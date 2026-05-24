package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;
import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult.DetectedProblem;
import com.ieum.backend.domain.problem.dto.internal.ClassificationResult;
import com.ieum.backend.domain.problem.dto.internal.OcrResult;
import com.ieum.backend.domain.problem.dto.internal.OcrResult.DetectedText;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
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

            ClassificationResult c = classifier.classify(t.getExtractedText(), examCode);

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

            problems.add(p);
        }

        AiAnalysisResult result = new AiAnalysisResult();
        result.setDetectedProblems(problems);
        return result;
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