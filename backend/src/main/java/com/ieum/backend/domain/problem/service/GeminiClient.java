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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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

        // (2) 한 문제 여러 장(SINGLE_MULTIPAGE): 순서대로 텍스트를 합쳐 "1개 문제"로 1회 분류.
        if (ocrResult.getMode() == OcrResult.OcrMode.SINGLE_MULTIPAGE
                && ocrResult.getPages() != null && !ocrResult.getPages().isEmpty()) {
            return analyzeSingleMultipage(ocrResult, images.size());
        }

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
            p.setProblemNumber(t.getProblemNumber()); // OCR 인식 문제 번호(강사 표시용)
            p.setImageIndices(t.getImageIndices());    // 이 문제가 걸친 이미지들(다중 선택 시 그 장들만 저장)
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
     * (2) SINGLE_MULTIPAGE — 한 문제가 여러 장에 걸친 경우.
     * suggestedOrder대로 장별 텍스트를 합쳐 하나의 본문으로 만들고 1회만 분류한다.
     * 정렬된 imageOrder/pageTexts를 결과에 실어, ProblemService가 이미지·텍스트를 같은 순서로 저장하게 한다.
     */
    private AiAnalysisResult analyzeSingleMultipage(OcrResult ocr, int imageCount) {
        // imageIndex → pageText 매핑
        Map<Integer, String> textByIndex = new HashMap<>();
        for (OcrResult.PageText p : ocr.getPages()) {
            textByIndex.put(p.getImageIndex(), p.getPageText() == null ? "" : p.getPageText());
        }

        // 정렬 순서: suggestedOrder 우선, 유효하지 않으면 업로드 순서로 폴백
        List<Integer> order = sanitizeOrder(ocr.getSuggestedOrder(), imageCount);
        log.info("OCR 완료 — 한 문제 {}장(SINGLE_MULTIPAGE), 적용 순서 {}", imageCount, order);

        // 순서대로 텍스트 재조합 + 정렬된 pageText 보관
        List<String> orderedPageTexts = new ArrayList<>();
        StringBuilder sb = new StringBuilder();
        for (int idx : order) {
            String t = textByIndex.getOrDefault(idx, "");
            orderedPageTexts.add(t);
            if (!t.isBlank()) {
                if (sb.length() > 0) sb.append("\n\n");
                sb.append(t.strip());
            }
        }
        String combined = sb.toString();

        String examCode = extractExamCode(combined);

        boolean classificationFailed = false;
        ClassificationResult c;
        try {
            c = classifier.classify(combined, examCode);
        } catch (RuntimeException e) {
            log.warn("분류 실패 — 기본값으로 등록 진행(SINGLE_MULTIPAGE): {}", e.getMessage());
            c = fallbackClassification(combined);
            classificationFailed = true;
        }

        ExamType finalExamType = c.getExamType();
        if (examCode != null) {
            ExamType estimated = estimateFromCode(examCode);
            if (estimated != null && finalExamType != estimated) {
                finalExamType = estimated;
            }
        }

        DetectedProblem p = new DetectedProblem();
        p.setExtractedText(combined);
        p.setSummary(c.getSummary());
        p.setSubject(c.getSubject());
        p.setPrimaryType(c.getPrimaryType());
        p.setSecondaryType(c.getSecondaryType());
        p.setDifficulty(c.getDifficulty());
        p.setTotalDifficultyScore(c.getTotalDifficultyScore());
        p.setExamType(finalExamType);
        p.setClassificationFailed(classificationFailed);

        AiAnalysisResult result = new AiAnalysisResult();
        result.setDetectedProblems(new ArrayList<>(List.of(p)));
        result.setMode(OcrResult.OcrMode.SINGLE_MULTIPAGE);
        result.setImageOrder(order);
        result.setPageTexts(orderedPageTexts);
        return result;
    }

    /**
     * suggestedOrder 보정 — 0..imageCount-1이 정확히 한 번씩 들어가야 유효.
     * 모델이 일부를 빠뜨리거나 범위를 벗어나면 업로드 순서로 안전 폴백한다.
     */
    private List<Integer> sanitizeOrder(List<Integer> suggested, int imageCount) {
        List<Integer> fallback = new ArrayList<>();
        for (int i = 0; i < imageCount; i++) fallback.add(i);

        if (suggested == null || suggested.size() != imageCount) return fallback;
        boolean[] seen = new boolean[imageCount];
        for (Integer idx : suggested) {
            if (idx == null || idx < 0 || idx >= imageCount || seen[idx]) return fallback;
            seen[idx] = true;
        }
        return new ArrayList<>(suggested);
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