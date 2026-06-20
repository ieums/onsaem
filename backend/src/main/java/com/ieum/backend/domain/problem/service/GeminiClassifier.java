package com.ieum.backend.domain.problem.service;

import com.ieum.backend.global.exception.BusinessException;

import com.fasterxml.jackson.core.json.JsonReadFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.ieum.backend.domain.problem.dto.internal.ClassificationResult;
import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 2단계: 텍스트 → 분류 (이미지 안 봄)
 * 이미 추출된 텍스트만 보고 subject/단원/난이도/examType을 판단.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GeminiClassifier {

    @Value("${gemini.api.key:none}")
    private String apiKey;

    private static final String GEMINI_URL =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

    private final RestTemplate restTemplate = new RestTemplate();
    private final ProblemTypeRegistry typeRegistry;

    private final ObjectMapper objectMapper = JsonMapper.builder()
            .enable(JsonReadFeature.ALLOW_BACKSLASH_ESCAPING_ANY_CHARACTER)
            .build();

    private String buildPrompt(String problemText, String examCode) {
        String codeInfo = (examCode != null && !examCode.isBlank())
                ? "이 문제의 EBS 코드: " + examCode + " (반드시 이 정보를 활용)"
                : "EBS 코드 정보 없음";

        return String.format("""
            당신은 한국 고등학교 학습 콘텐츠 분류 전문가입니다.
            아래 문제 텍스트를 분석하여 분류 정보를 JSON으로 출력하세요.
            JSON만 출력. 마크다운 코드블록(```) 금지. 다른 텍스트 절대 금지.
            
            ─────────────────────────────────────────────
            [입력 정보]
            ─────────────────────────────────────────────
            %s
            
            [문제 텍스트]
            %s
            
            ─────────────────────────────────────────────
            [응답 구조]
            ─────────────────────────────────────────────
            {
              "summary": "핵심 한 줄 요약 (40자 이내)",
              "subject": "KOREAN | MATH | ENGLISH | SOCIAL | SCIENCE",
              "primaryType": "아래 목록에서 정확히 선택",
              "secondaryType": "위 primaryType에 해당하는 목록에서 정확히 선택",
              "difficulty": "EASY | MEDIUM | HARD",
              "totalDifficultyScore": 0~100,
              "examType": "SUNUNG | MOCK_EVALUATION | ACADEMIC_EVALUATION | EBS_SUNEUNG_TEUKGANG | EBS_SUNEUNG_WANSUNG | SCHOOL_INTERNAL | ACADEMY | null"
            }
            
            ─────────────────────────────────────────────
            [과목 판단]
            ─────────────────────────────────────────────
            - "다음 글을 읽고", "윗글을 읽고", "<보기>를 읽고" → 무조건 KOREAN (독서)
            - 지문 주제가 과학/사회여도 독해 형태면 KOREAN
            - SCIENCE/SOCIAL은 단원 개념을 직접 묻는 경우만
              예: "수요의 가격 탄력성을 구하시오" → SOCIAL (경제)
              예: "운동량 보존 법칙으로 풀어라" → SCIENCE (물리)
            
            ─────────────────────────────────────────────
            [examType 판별 — 매우 중요]
            ─────────────────────────────────────────────
            ★ 1순위: EBS 코드 [25xxx-xxxx]가 있으면 무조건 EBS 교재
              - 과목코드(3자리) 030 이하 → EBS_SUNEUNG_TEUKGANG (수능특강)
              - 과목코드(3자리) 040 이상 → EBS_SUNEUNG_WANSUNG (수능완성)
              - 예: [25002-0021] → 002 → EBS_SUNEUNG_TEUKGANG
              - 예: [25054-0011] → 054 → EBS_SUNEUNG_WANSUNG
              → 절대 SUNUNG/MOCK/ACADEMIC으로 분류 금지
            
            ★ 2순위: EBS 코드가 없을 때만 다음 단서로 판단
              - "대학수학능력시험" → SUNUNG
              - "전국연합학력평가" → ACADEMIC_EVALUATION
              - "○월 모의평가" + 평가원 → MOCK_EVALUATION
              - 학교명 + "중간/기말고사" → SCHOOL_INTERNAL
              - 학원명 → ACADEMY
            
            ★ 3순위: 단서 전혀 없음 → null
            
            ─────────────────────────────────────────────
            [난이도 — totalDifficultyScore 0~100]
            ─────────────────────────────────────────────
            매핑: 0~33 EASY, 34~66 MEDIUM, 67~100 HARD
            
            ■ SUNUNG/MOCK/ACADEMIC:
              문항번호(30%%) + 출제영역(20%%) + 풀이단계(25%%) + 개념복합도(15%%) + 계산량(10%%)
              - 1~10번=하, 11~20번=중, 21·29·30번=상
            
            ■ 그 외 (EBS/내신/학원/불명):
              출제영역(25%%) + 풀이단계(35%%) + 개념복합도(25%%) + 계산량(15%%)
            
            ■ 영역별 일반 난이도
              - 수학: 수학1 < 수학2 < 미적분 ≈ 기하
              - 국어 독서: 인문 ≈ 사회 < 예술 < 과학기술
              - 국어 문학: 현대시 < 고전시가 < 고전소설
              - 영어 독해: 주제찾기 < 요지파악 < 빈칸추론 ≈ 함축의미
            
            ─────────────────────────────────────────────
            [1차유형 목록]
            ─────────────────────────────────────────────
            %s
            
            ─────────────────────────────────────────────
            [2차유형 목록]
            ─────────────────────────────────────────────
            %s
            
            ─────────────────────────────────────────────
            [최종 체크]
            ─────────────────────────────────────────────
            ☐ subject는 5개 enum 중 하나
            ☐ primaryType은 subject에 맞는 목록 안의 값
            ☐ secondaryType은 primaryType에 맞는 목록 안의 값
            ☐ EBS 코드가 있는데 SUNUNG/MOCK/ACADEMIC으로 분류하지 않았는가
            ☐ JSON만 출력, 다른 텍스트 없음
            """,
                codeInfo,
                problemText,
                typeRegistry.buildPrimaryTypePromptSection(),
                typeRegistry.buildSecondaryTypePromptSection()
        );
    }

    public ClassificationResult classify(String problemText, String examCode) {
        if ("none".equals(apiKey)) {
            log.warn("Gemini API 키 없음. Mock 분류 결과 반환.");
            return mockClassification();
        }
        try {
            return callApi(problemText, examCode);
        } catch (Exception e) {
            log.error("분류 API 호출 실패", e);
            throw BusinessException.internalError("분류 API 호출 실패: " + e.getMessage(), e);
        }
    }

    private ClassificationResult callApi(String problemText, String examCode) throws Exception {
        // 텍스트만 보내는 호출 — 이미지 X
        Map<String, Object> requestBody = Map.of(
                "contents", List.of(Map.of(
                        "parts", List.of(Map.of("text", buildPrompt(problemText, examCode)))
                )),
                "generationConfig", Map.of(
                        "response_mime_type", "application/json",
                        "temperature", 0.2
                )
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

        String urlWithKey = GEMINI_URL + "?key=" + apiKey;
        ResponseEntity<String> response = restTemplate.postForEntity(urlWithKey, request, String.class);

        return parseResponse(response.getBody());
    }

    private ClassificationResult parseResponse(String responseBody) {
        try {
            JsonNode root = objectMapper.readTree(responseBody);

            String text = root
                    .path("candidates").get(0)
                    .path("content")
                    .path("parts").get(0)
                    .path("text")
                    .asText();

            text = text.replaceAll("```json\\s*", "")
                    .replaceAll("```\\s*", "")
                    .trim();

            JsonNode json = objectMapper.readTree(text);

            ClassificationResult r = new ClassificationResult();
            r.setSummary(json.path("summary").asText(""));
            r.setTotalDifficultyScore(json.path("totalDifficultyScore").asInt(50));
            r.setSubject(parseEnum(Subject.class, json.path("subject").asText(null)));
            r.setDifficulty(parseEnum(Difficulty.class, json.path("difficulty").asText(null)));
            r.setExamType(parseEnum(ExamType.class, json.path("examType").asText(null)));

            // 단원명 검증
            String rawPrimary = json.path("primaryType").asText(null);
            String rawSecondary = json.path("secondaryType").asText(null);

            String validatedPrimary = typeRegistry.validatePrimaryType(r.getSubject(), rawPrimary);
            if (validatedPrimary == null && rawPrimary != null) {
                log.warn("primaryType 검증 실패: subject={}, value={}", r.getSubject(), rawPrimary);
            }
            r.setPrimaryType(validatedPrimary);

            String validatedSecondary = typeRegistry.validateSecondaryType(validatedPrimary, rawSecondary);
            if (validatedSecondary == null && rawSecondary != null) {
                log.warn("secondaryType 검증 실패: primary={}, value={}", validatedPrimary, rawSecondary);
            }
            r.setSecondaryType(validatedSecondary);

            return r;

        } catch (Exception e) {
            throw BusinessException.internalError("분류 응답 파싱 실패: " + e.getMessage(), e);
        }
    }

    private <E extends Enum<E>> E parseEnum(Class<E> enumClass, String value) {
        if (value == null || value.isBlank() || "null".equalsIgnoreCase(value)) {
            return null;
        }
        try {
            return Enum.valueOf(enumClass, value.trim().toUpperCase());
        } catch (Exception e) {
            log.warn("Enum 파싱 실패: {} → {}", enumClass.getSimpleName(), value);
            return null;
        }
    }

    private ClassificationResult mockClassification() {
        ClassificationResult r = new ClassificationResult();
        r.setSummary("(Mock) 이차함수 최솟값");
        r.setSubject(Subject.MATH);
        r.setPrimaryType("공통수학1");
        r.setSecondaryType("방정식과부등식");
        r.setDifficulty(Difficulty.EASY);
        r.setTotalDifficultyScore(25);
        r.setExamType(null);
        return r;
    }
}