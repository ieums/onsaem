package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;
import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult.DetectedProblem;
import com.ieum.backend.domain.problem.dto.internal.ClassificationResult;
import com.ieum.backend.domain.problem.dto.internal.OcrResult;
import com.ieum.backend.domain.problem.dto.internal.OcrResult.DetectedText;
import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 오케스트레이터: OCR 단계 + 분류 단계를 순서대로 실행해 최종 결과 조립
 *
 * 흐름:
 * 1. GeminiOcrClient → 이미지에서 문제별 텍스트 추출
 * 2. 각 텍스트마다 GeminiClassifier → 분류 정보 획득
 * 3. 두 결과를 합쳐 DetectedProblem 리스트로 반환
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GeminiClient {

    private final GeminiOcrClient ocrClient;
    private final GeminiClassifier classifier;

    private static final Pattern EBS_CODE_PATTERN =
            Pattern.compile("\\[25(\\d{3})-\\d{4}]");

    public AiAnalysisResult analyze(List<MultipartFile> images) {
        // 1단계: OCR
        log.info("1단계 OCR 시작 — 이미지 {}장", images.size());
        OcrResult ocrResult = ocrClient.extract(images);
        log.info("OCR 완료 — 감지된 문제 {}개", ocrResult.getDetectedTexts().size());

        // 2단계: 각 문제마다 분류
        List<DetectedProblem> problems = new ArrayList<>();
        String previousCode = null;
        for (int i = 0; i < ocrResult.getDetectedTexts().size(); i++) {
            DetectedText t = ocrResult.getDetectedTexts().get(i);

            String examCode = t.getExamCode();
            if (examCode == null && t.getExtractedText() != null) {
                examCode = extractExamCode(t.getExtractedText());
            }

            // 중복 코드 감지
            if (previousCode != null && previousCode.equals(examCode)) {
                log.warn("⚠️ 이전 문제와 같은 examCode 사용: {} — OCR이 코드를 잘못 매칭했을 수 있음", examCode);
            }
            previousCode = examCode;

            log.info("2단계 분류 시작 — 문제 {}/{} (examCode: {})",
                    i + 1, ocrResult.getDetectedTexts().size(), examCode);

            // 분류 실패(과부하 503 등)는 치명적이지 않다 — 기본값으로 채워 등록은 진행하고,
            // 프론트가 분류 수정 화면으로 유도하도록 classificationFailed 플래그를 남긴다.
            boolean classificationFailed = false;
            ClassificationResult c;
            try {
                c = classifier.classify(t.getExtractedText(), examCode);
            } catch (RuntimeException e) {
                log.warn("분류 실패 — 기본값으로 등록 진행(문제 {}/{}): {}",
                        i + 1, ocrResult.getDetectedTexts().size(), e.getMessage());
                c = fallbackClassification(t.getExtractedText());
                classificationFailed = true;
            }

            // examType 안전망: 코드가 있는데 EBS로 분류 안 됐으면 강제 보정
            ExamType finalExamType = c.getExamType();
            if (examCode != null) {
                ExamType estimated = estimateFromCode(examCode);
                if (estimated != null && finalExamType != estimated) {
                    log.warn("examType 강제 보정: {} → {} (코드 기반)",
                            finalExamType, estimated);
                    finalExamType = estimated;
                }
            }

            // DetectedProblem 조립
            DetectedProblem p = new DetectedProblem();
            p.setExtractedText(t.getExtractedText());
            p.setSummary(c.getSummary());
            p.setSubject(c.getSubject());
            p.setPrimaryType(c.getPrimaryType());
            p.setSecondaryType(c.getSecondaryType());
            p.setDifficulty(c.getDifficulty());
            p.setTotalDifficultyScore(c.getTotalDifficultyScore());
            p.setExamType(finalExamType);
            p.setClassificationFailed(classificationFailed);

            problems.add(p);
        }

        AiAnalysisResult result = new AiAnalysisResult();
        result.setDetectedProblems(problems);
        return result;
    }

    /**
     * 분류 API 실패 시 기본값. 과목은 어차피 학생 선택값이 우선하므로 UNKNOWN,
     * 나머지는 미분류/보통으로 채워 등록만 진행한다(이후 학생이 분류 수정 화면에서 보정).
     */
    private ClassificationResult fallbackClassification(String text) {
        ClassificationResult r = new ClassificationResult();
        r.setSummary(buildSummaryFromText(text));
        r.setSubject(Subject.UNKNOWN);
        r.setPrimaryType(null);
        r.setSecondaryType(null);
        r.setDifficulty(Difficulty.MEDIUM);
        r.setTotalDifficultyScore(50);
        r.setExamType(ExamType.UNKNOWN);
        return r;
    }

    private String buildSummaryFromText(String text) {
        if (text == null || text.isBlank()) return "분류 대기 중인 문제";
        String s = text.strip().replaceAll("\\s+", " ");
        return s.length() > 30 ? s.substring(0, 30) + "…" : s;
    }

    /**
     * 텍스트에서 [25xxx-xxxx] 패턴 추출 (OCR 결과 보강용)
     */
    private String extractExamCode(String text) {
        Matcher m = EBS_CODE_PATTERN.matcher(text);
        return m.find() ? m.group(0) : null;
    }

    /**
     * 코드의 과목번호로 수특/수완 결정
     */
    private ExamType estimateFromCode(String examCode) {
        Matcher m = EBS_CODE_PATTERN.matcher(examCode);
        if (m.find()) {
            int code = Integer.parseInt(m.group(1));
            return code >= 40 ? ExamType.EBS_SUNEUNG_WANSUNG : ExamType.EBS_SUNEUNG_TEUKGANG;
        }
        return null;
    }
}