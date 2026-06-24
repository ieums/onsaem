package com.ieum.backend.domain.problem.service;

import com.fasterxml.jackson.core.json.JsonReadFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.ieum.backend.domain.problem.dto.internal.OcrResult;
import com.ieum.backend.global.exception.BusinessException;
import com.ieum.backend.domain.problem.dto.internal.OcrResult.DetectedText;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 1단계: 이미지 → 텍스트 추출 (OCR 전담)
 * 분류·난이도 판단은 하지 않음. OCR과 묶음 인식만.
 */
@Slf4j
@Service
public class GeminiOcrClient {

    @Value("${gemini.api.key:none}")
    private String apiKey;

    // OCR은 빽빽한 한글 vision 작업이라 lite는 반복 루프에 빠지기 쉬움 → flash 이상 권장.
    // 더 센 모델(gemini-2.5-pro)로 올리려면 application-local.yml에서 ocr-model 교체.
    @Value("${gemini.api.ocr-model:gemini-2.5-flash}")
    private String model;

    // thinking 예산. flash/flash-lite는 0으로 끌 수 있고, 2.5-pro는 0 불가(-1=자동/동적).
    @Value("${gemini.api.ocr-thinking-budget:0}")
    private int thinkingBudget;

    private String geminiUrl() {
        return "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent";
    }

    private final RestTemplate restTemplate = new RestTemplate();

    private final ObjectMapper objectMapper = JsonMapper.builder()
            .enable(JsonReadFeature.ALLOW_BACKSLASH_ESCAPING_ANY_CHARACTER)
            .build();

    private static final String OCR_PROMPT = """
            당신은 한국 고등학교 학습 자료의 OCR 전문가입니다.
            첨부된 이미지에서 문제 텍스트만 추출하세요.
            분류, 난이도, 출처 판단은 절대 하지 마세요. 오직 텍스트 추출과 묶음 인식만 합니다.
            JSON만 출력하세요. 마크다운 코드블록(```) 절대 사용 금지.
            
            ─────────────────────────────────────────────
            [응답 구조]
            ─────────────────────────────────────────────
            {
              "detectedTexts": [
                {
                  "extractedText": "지문 + 문제 발문 + 선택지 전체",
                  "examCode": "[25002-0021] (보이면 그대로, 없으면 null)",
                  "problemNumber": 1 (문제 번호, 없으면 null)
                }
              ]
            }
            
            ─────────────────────────────────────────────
            [핵심 원칙]
            ─────────────────────────────────────────────
            
            1. 1개 문제 = 1개 detectedText 객체
               - 묶음 번호 [01~03]이 있고 01, 02, 03번이 같은 지문을 공유하면
                 → 각 문제마다 별도 객체로 분리 (지문은 객체마다 반복 OK)
               - 한 문제의 내용이 페이지에 걸쳐 분할되면 → 합쳐서 1개 객체
            
            2. 보이는 만큼만, 보이는 그대로
               - 이미지에 01, 02만 보이면 → 배열 길이 = 2
               - "03도 있겠지" 추측 금지
               - 안 보이는 선택지는 [보이지 않음]으로 표시
               - 비슷한 문장으로 빈 곳을 채우지 말 것
            
            3. 원문 보존 — 의역 절대 금지
               - 발문 "일치하지 않는 것은?" → 그대로
               - "원자 폭탄 투하" → 그대로 (의역 X)
               - OCR이 어려운 부분은 [흐릿함] 표시
            
            ─────────────────────────────────────────────
            [기호 정확하게 구분 — 매우 중요]
            ─────────────────────────────────────────────
            세 종류 동그라미를 절대 혼동하지 말 것:
              • 영문: ⓐ ⓑ ⓒ ⓓ ⓔ ⓕ ⓖ ⓗ
              • 한글: ㉠ ㉡ ㉢ ㉣ ㉤ ㉥ ㉦ ㉧
              • 숫자: ① ② ③ ④ ⑤ ⑥ ⑦ ⑧
            
            구분 방법:
              - 옆 글자가 한글이면 한글 동그라미 (㉠)일 가능성 높음
                예: "㉠레짐 이론" — '레'가 한글이므로 ㉠
              - 옆 글자가 영문이면 영문 동그라미 (ⓐ)일 가능성 높음
              - 한 문서 안에 두 종류가 섞여 나올 수 있음. 각각 다르게 보고 구분
            
            ─────────────────────────────────────────────
            [examCode 추출 — 매우 중요]
            ─────────────────────────────────────────────
            [25xxx-xxxx] 형식의 코드가 어디 보이면 (작은 글씨여도) examCode에 옮길 것.
    
             ★ 각 문제마다 자기 코드만 매칭하기 ★
                - 01번 문제 근처에 [25002-0021]이 있고, 02번 문제 근처에 [25002-0022]가 있다면:
                  → 01번 객체의 examCode = "[25002-0021]"
                  → 02번 객체의 examCode = "[25002-0022]"
                - 코드는 보통 문제 번호의 바로 위 또는 아래에 작게 적혀 있음
                - 다른 문제의 코드를 가져다 쓰지 말 것
                - 같은 EBS 교재 안에서 문제마다 코드 끝 4자리가 다름 (0021, 0022, 0023...)
    
             ★ extractedText에도 자기 문제 코드만 포함 ★
                - 01번 객체의 extractedText에는 [25002-0021]만
                - 02번 객체의 extractedText에는 [25002-0022]만
                - 다른 문제 코드를 임의로 채워넣지 말 것
    
            코드가 정말 안 보이면 null. 추측 금지.
            
            ─────────────────────────────────────────────
            [OCR 정확도 향상]
            ─────────────────────────────────────────────
            - 밑줄·굵은체가 글자와 겹치면 오인되기 쉬움
            - 학술 용어 옆에 영어 원어가 (괄호)로 병기되어 있으면 영어로 한국어 보정
              예: "??? 이론(regime theory)" → "레짐 이론(regime theory)"
           
            [누락 금지 — 일반 원칙]
            - 본문에 보이는 모든 단어를 옮길 것. 의미적으로 어색해 보여도 그대로.
            - 한자, 숫자, 특수기호, 작은 글씨, 약자도 누락 금지.
            - 인식이 100% 확실하지 않은 글자는 [흐릿함]으로 표시. 단, 단어 자체는 절대 삭제 금지.
            - "자연스러운 문장 만들기"보다 "원문 보존"이 우선.
            
            ─────────────────────────────────────────────
            [extractedText 형식 규칙]
            ─────────────────────────────────────────────
            - 백슬래시(\\\\) 절대 사용 금지
            - LaTeX 대신 유니코드: √ ∫ ∑ π ∞ ≤ ≥ ≠ ± × ÷ x² x₁ (a/b)
            - 줄바꿈은 \\\\n으로 이스케이프
            - 큰따옴표는 \\\\"로 이스케이프
            
            ─────────────────────────────────────────────
            [최종 체크]
            ─────────────────────────────────────────────
            ☐ 보이는 문제 개수와 detectedTexts 배열 길이가 일치
            ☐ [25xxx-xxxx] 코드가 이미지에 있으면 examCode에 옮김
            ☐ 영문/한글 동그라미를 옆 글자로 구분
            ☐ 발문·본문을 의역하지 않고 원문 그대로
            ☐ 백슬래시 없음
            """;

    private static final int MAX_ATTEMPTS = 3;

    public OcrResult extract(List<MultipartFile> images) {
        if ("none".equals(apiKey)) {
            log.warn("Gemini API 키 없음. Mock OCR 결과 반환.");
            return mockOcr();
        }
        // 여러 장이 한 세트(지문이 페이지에 걸침, 문제가 다른 페이지)일 수 있어 한 번에 보낸다.
        // 출력이 길어 잘리던 문제는 maxOutputTokens를 모델 최대치로 올려 대응.
        for (int attempt = 1; ; attempt++) {
            try {
                return callApi(images);
            } catch (HttpStatusCodeException e) {
                // 503/502/500/429 등 일시 과부하·레이트리밋이면 잠깐 쉬고 재시도
                boolean transientError =
                        e.getStatusCode().is5xxServerError() || e.getStatusCode().value() == 429;
                if (transientError && attempt < MAX_ATTEMPTS) {
                    log.warn("OCR 일시 오류({}) — 재시도 {}/{}", e.getStatusCode(), attempt, MAX_ATTEMPTS);
                    backoff(attempt);
                    continue;
                }
                log.error("OCR API 호출 실패", e);
                throw BusinessException.internalError("OCR API 호출 실패: " + e.getMessage(), e);
            } catch (Exception e) {
                log.error("OCR API 호출 실패", e);
                throw BusinessException.internalError("OCR API 호출 실패: " + e.getMessage(), e);
            }
        }
    }

    /** 재시도 전 백오프 대기 (1초, 2초 …) */
    private static void backoff(int attempt) {
        try {
            Thread.sleep(1000L * attempt);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }

    private OcrResult callApi(List<MultipartFile> images) throws Exception {
        List<Map<String, Object>> parts = new ArrayList<>();
        parts.add(Map.of("text", OCR_PROMPT));

        int total = images.size();
        for (int i = 0; i < total; i++) {
            MultipartFile image = images.get(i);

            parts.add(Map.of("text",
                    "[페이지 " + (i + 1) + " / 총 " + total + "]"));

            String base64 = Base64.getEncoder().encodeToString(image.getBytes());
            String mimeType = image.getContentType() != null
                    ? image.getContentType()
                    : "image/jpeg";

            Map<String, Object> inlineData = new HashMap<>();
            inlineData.put("mime_type", mimeType);
            inlineData.put("data", base64);
            parts.add(Map.of("inline_data", inlineData));
        }

        Map<String, Object> requestBody = Map.of(
                "contents", List.of(Map.of("parts", parts)),
                "generationConfig", Map.of(
                        "response_mime_type", "application/json",
                        "temperature", 0.1,           // OCR은 더 낮게
                        "maxOutputTokens", 65536, // 한 장이라도 문제가 많으면 출력이 길어 잘릴 수 있음 → 모델 최대치
                        // thinking 예산은 설정값. flash=0(끔), pro=-1(자동) 권장.
                        "thinkingConfig", Map.of("thinkingBudget", thinkingBudget)
                )
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

        String urlWithKey = geminiUrl() + "?key=" + apiKey;
        ResponseEntity<String> response = restTemplate.postForEntity(urlWithKey, request, String.class);

        return parseResponse(response.getBody());
    }

    private OcrResult parseResponse(String responseBody) {
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

            OcrResult result = new OcrResult();
            List<DetectedText> list = new ArrayList<>();

            JsonNode array = json.path("detectedTexts");
            if (array.isArray()) {
                for (JsonNode item : array) {
                    list.add(mapToDetectedText(item));
                }
            } else {
                list.add(mapToDetectedText(json));
            }

            result.setDetectedTexts(list);
            return result;

        } catch (Exception e) {
            // 모델 출력이 잘리거나 형식이 깨지면 여기로 옴 → 사용자에게 알아들을 메시지
            throw BusinessException.internalError(
                    "문제 인식 결과 처리에 실패했어요. 사진을 더 적게/선명하게 올려 다시 시도해 주세요.", e);
        }
    }

    private DetectedText mapToDetectedText(JsonNode node) {
        DetectedText t = new DetectedText();
        t.setExtractedText(node.path("extractedText").asText(""));

        String examCode = node.path("examCode").asText(null);
        t.setExamCode((examCode == null || examCode.isBlank() || "null".equalsIgnoreCase(examCode))
                ? null : examCode);

        JsonNode numNode = node.path("problemNumber");
        t.setProblemNumber(numNode.isInt() ? numNode.asInt() : null);

        return t;
    }

    private OcrResult mockOcr() {
        DetectedText t = new DetectedText();
        t.setExtractedText("(Mock OCR) 함수 f(x) = x² + 2x + 1의 최솟값을 구하시오.");
        t.setExamCode(null);
        t.setProblemNumber(1);

        OcrResult r = new OcrResult();
        r.setDetectedTexts(List.of(t));
        return r;
    }
}