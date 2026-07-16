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
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
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

    // 기본 모델이 과부하(503)면 자동으로 갈아탈 폴백 모델. 보통 더 안정적인(가용성↑) 모델.
    @Value("${gemini.api.ocr-fallback-model:gemini-2.5-flash}")
    private String fallbackModel;

    // thinking 예산. flash/flash-lite는 0으로 끌 수 있고, 2.5-pro는 0 불가(-1=자동/동적).
    @Value("${gemini.api.ocr-thinking-budget:0}")
    private int thinkingBudget;

    private String geminiUrl(String useModel) {
        return "https://generativelanguage.googleapis.com/v1beta/models/" + useModel + ":generateContent";
    }

    // 한 호출이 무한 대기하지 않도록 connect/read 타임아웃을 건다.
    // (read 80초: 이미지 여러 장 OCR이 길어질 때도 정상 호출은 끊기지 않게 넉넉히)
    private final RestTemplate restTemplate = buildRestTemplate();

    private static RestTemplate buildRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(5));
        factory.setReadTimeout(Duration.ofSeconds(80));
        return new RestTemplate(factory);
    }

    private final ObjectMapper objectMapper = JsonMapper.builder()
            .enable(JsonReadFeature.ALLOW_BACKSLASH_ESCAPING_ANY_CHARACTER)
            .build();

    private static final String OCR_PROMPT = """
            당신은 한국 고등학교 학습 자료의 OCR 전문가입니다.
            첨부된 이미지에서 문제 텍스트만 추출하세요.
            분류, 난이도, 출처 판단은 절대 하지 마세요. 오직 텍스트 추출과 묶음 인식만 합니다.
            JSON만 출력하세요. 마크다운 코드블록(```) 절대 사용 금지.

            ─────────────────────────────────────────────
            [먼저 mode를 판단하세요 — 매우 중요]
            ─────────────────────────────────────────────
            업로드된 이미지(들)가 어느 경우인지 먼저 정합니다.

            • "SINGLE_MULTIPAGE" = 여러 장이 사실 "한 문제"인 경우
              - 긴 지문(국어/영어 등)이 여러 장에 걸쳐 잘려 있고, 하나의 발문/선택지 세트를 공유
              - 문제 번호가 하나뿐이거나, 번호 없이 지문이 이어짐
              - 학생이 페이지를 순서대로 안 올렸을 수 있음 → suggestedOrder로 올바른 순서를 알려줌

              ★ 단, 아래 중 하나라도 해당하면 SINGLE_MULTIPAGE가 아니라 무조건 MULTI_PROBLEM:
                - 서로 다른 과목이 둘 이상 보임 (예: 국어 + 영어, 수학 + 영어)
                - 서로 다른 발문/문제 번호가 둘 이상 보임 (예: 01·02 … 또는 독립된 문제들)
                - 각 장이 서로 독립된 문제로 보임(지문이 이어지지 않음)
              → SINGLE_MULTIPAGE는 "정말로 한 문제(한 과목·한 발문 세트)가 여러 장에 잘린" 경우에만.

            • "MULTI_PROBLEM" = 그 외 전부 (기본값)
              - 서로 다른 문제가 여러 개(번호 01, 02, 03…)
              - 서로 다른 과목이 섞여 있는 경우
              - 또는 한 장에 한 문제만 있는 단순한 경우
              - 이 경우 각 문제의 imageIndices로 "그 문제가 몇 번째 장에 있는지"만 정확히 표시.

            애매하면 "MULTI_PROBLEM"으로 둡니다. (단일 문제 단일 장도 MULTI_PROBLEM)

            ─────────────────────────────────────────────
            [응답 구조]
            ─────────────────────────────────────────────
            mode에 따라 채우는 필드가 다릅니다.

            (A) mode = "MULTI_PROBLEM" 일 때:
            {
              "mode": "MULTI_PROBLEM",
              "detectedTexts": [
                {
                  "extractedText": "지문 + 문제 발문 + 선택지 전체",
                  "examCode": "[25002-0021] (보이면 그대로, 없으면 null)",
                  "problemNumber": 1 (문제 번호, 없으면 null),
                  "imageIndices": [0] (이 문제가 보이는 이미지 번호들 = [페이지 N] 라벨의 N-1)
                }
              ]
            }
            ★ imageIndices: 각 문제가 "어느 이미지(들)에 있는지"를 정확히. 위 [페이지 N / 총 M] 라벨을 보고 N-1을 배열로.
              - 한 문제가 한 장에만 있으면 [0] 처럼 1개.
              - 한 문제가 여러 장에 걸치면(긴 지문 등) [0,1] 처럼 모두 넣어라.
              - 서로 다른 장의 다른 문제는 imageIndices가 겹치지 않아야 함. 모르면 [0].

            (B) mode = "SINGLE_MULTIPAGE" 일 때:
            {
              "mode": "SINGLE_MULTIPAGE",
              "pages": [
                { "imageIndex": 0, "pageText": "0번째 이미지에서 추출한 텍스트" },
                { "imageIndex": 1, "pageText": "1번째 이미지에서 추출한 텍스트" }
              ],
              "suggestedOrder": [1, 0]   // 올바른 읽기 순서(이미지 인덱스). 페이지가 한 장이면 [0]
            }
            - imageIndex는 위 [페이지 N / 총 M] 라벨의 N-1 (업로드 순서, 0부터).
            - pageText는 그 장에 보이는 그대로. 의역/보충 금지.
            - suggestedOrder는 지문 흐름(쪽 번호, 문장 연결, 문단 이어짐)으로 판단한 올바른 순서.
              근거가 약하면 업로드 순서 그대로(0,1,2…) 두세요. 모든 imageIndex가 정확히 한 번씩 들어가야 함.

            ─────────────────────────────────────────────
            [핵심 원칙] (mode = MULTI_PROBLEM)
            ─────────────────────────────────────────────

            1. "문제"의 정의 — 발문 + (보통)선택지가 있는, 번호 매겨진 질문만
               - 실제 문제 = 발문(예: "~것은?", "~고르시오", "구하시오")과 보통 선택지(①②③④⑤)를 가진 질문.
               - "[01~03] 다음 글을 읽고 물음에 답하시오." 같은 안내문, 긴 지문, <보기>는
                 그 자체로는 문제가 아니다 → 단독 detectedText로 절대 만들지 말 것.
               - 안내문·지문·<보기>는 그 묶음에 속한 각 "실제 문제" 객체의 extractedText 안에 함께 넣어라(지문 반복 OK).
               - 1개 실제 문제 = 1개 detectedText. 묶음 [01~03]에서 01·02·03이 지문을 공유하면 각 문제마다 별도 객체.
               - 한 문제가 페이지에 걸쳐 분할되면 → 합쳐서 1개 객체.
               - ★ 이미지에 발문/선택지를 가진 "실제 문제"가 하나도 없고 안내문·지문만 보이면,
                 그걸로 가짜 문제를 만들지 말 것(그 묶음은 detectedTexts에서 제외).

            1-1. problemNumber 규칙 — 매우 중요
               - problemNumber는 "실제 문제"에 붙은 '단독' 번호만 (예: 1, 2, 19, 34).
               - "[01~03]", "[01-05]" 처럼 대괄호 안 범위/묶음 표기의 숫자를 problemNumber로 절대 쓰지 말 것.
                 이건 "어느 문제들이 지문을 공유하는지" 알려주는 범위일 뿐, 문제 번호가 아니다.
               - 이미지에 단독 문제 번호가 안 보이면 problemNumber = null (범위 표기에서 추측 금지).

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
            ☐ mode를 SINGLE_MULTIPAGE / MULTI_PROBLEM 중 하나로 명시
            ☐ 안내문("다음 글을 읽고 물음에 답하시오")·지문·<보기>만으로 가짜 문제를 만들지 않음
            ☐ [01~03] 같은 범위/묶음 숫자를 problemNumber로 쓰지 않음(단독 번호만)
            ☐ MULTI_PROBLEM: 보이는 "실제 문제"(발문+선택지) 개수와 detectedTexts 배열 길이가 일치
            ☐ SINGLE_MULTIPAGE: pages가 업로드 장수와 일치, suggestedOrder에 모든 인덱스 1회씩
            ☐ [25xxx-xxxx] 코드가 이미지에 있으면 examCode에 옮김
            ☐ 영문/한글 동그라미를 옆 글자로 구분
            ☐ 발문·본문을 의역하지 않고 원문 그대로
            ☐ 백슬래시 없음
            """;

    // 503은 즉시 응답이라 재시도가 싸지만, 총 처리시간을 FE 타임아웃 안에 두려고 예산을 줄였다.
    private static final int PRIMARY_ATTEMPTS = 2;
    private static final int FALLBACK_ATTEMPTS = 1;

    public OcrResult extract(List<MultipartFile> images) {
        if ("none".equals(apiKey)) {
            log.warn("Gemini API 키 없음. Mock OCR 결과 반환.");
            return mockOcr();
        }
        // 여러 장이 한 세트(지문이 페이지에 걸침, 문제가 다른 페이지)일 수 있어 한 번에 보낸다.
        // 출력이 길어 잘리던 문제는 maxOutputTokens를 모델 최대치로 올려 대응.
        try {
            return callWithRetries(images, model, PRIMARY_ATTEMPTS);
        } catch (HttpStatusCodeException e) {
            // 기본 모델이 일시 과부하면(503/5xx/429) → 폴백 모델로 한 번 더 시도
            if (isTransient(e) && fallbackModel != null
                    && !fallbackModel.isBlank() && !fallbackModel.equals(model)) {
                log.warn("OCR 기본모델({}) 과부하({}) — 폴백모델({})로 재시도",
                        model, e.getStatusCode(), fallbackModel);
                try {
                    return callWithRetries(images, fallbackModel, FALLBACK_ATTEMPTS);
                } catch (Exception fe) {
                    log.error("OCR 폴백모델도 실패", fe);
                    throw overloadException(fe);
                }
            }
            log.error("OCR API 호출 실패", e);
            throw isTransient(e)
                    ? overloadException(e)
                    : BusinessException.internalError("문제 분석에 실패했어요. 잠시 후 다시 시도해 주세요.", e);
        } catch (Exception e) {
            log.error("OCR API 호출 실패", e);
            throw BusinessException.internalError("문제 분석에 실패했어요. 잠시 후 다시 시도해 주세요.", e);
        }
    }

    /** 한 모델로 maxAttempts까지 재시도(일시 오류만). 소진되면 예외를 그대로 던진다. */
    private OcrResult callWithRetries(List<MultipartFile> images, String useModel, int maxAttempts)
            throws Exception {
        for (int attempt = 1; ; attempt++) {
            try {
                return callApi(images, useModel);
            } catch (HttpStatusCodeException e) {
                if (isTransient(e) && attempt < maxAttempts) {
                    log.warn("OCR 일시 오류({}) — {} 재시도 {}/{}",
                            e.getStatusCode(), useModel, attempt, maxAttempts);
                    backoff(attempt);
                    continue;
                }
                throw e;
            }
        }
    }

    /** 503/5xx/429 = 일시적 과부하·레이트리밋 */
    private boolean isTransient(HttpStatusCodeException e) {
        return e.getStatusCode().is5xxServerError() || e.getStatusCode().value() == 429;
    }

    /** 사용자에게 보여줄 깨끗한 과부하 메시지(raw 응답 노출 금지). */
    private BusinessException overloadException(Throwable cause) {
        return BusinessException.serviceUnavailable(
                "지금 AI 분석 요청이 많아 혼잡해요. 잠시 후 다시 시도해 주세요.", cause);
    }

    /** 재시도 전 백오프 대기 (1초, 2초 …) */
    private static void backoff(int attempt) {
        try {
            Thread.sleep(1000L * attempt);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }

    private OcrResult callApi(List<MultipartFile> images, String useModel) throws Exception {
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

        String urlWithKey = geminiUrl(useModel) + "?key=" + apiKey;
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

            // mode 판단 (없으면 기존 호환 위해 MULTI_PROBLEM)
            String modeStr = json.path("mode").asText("MULTI_PROBLEM");
            boolean singleMultipage = "SINGLE_MULTIPAGE".equalsIgnoreCase(modeStr)
                    && json.path("pages").isArray() && json.path("pages").size() > 0;

            if (singleMultipage) {
                result.setMode(OcrResult.OcrMode.SINGLE_MULTIPAGE);
                List<OcrResult.PageText> pages = new ArrayList<>();
                for (JsonNode item : json.path("pages")) {
                    OcrResult.PageText pt = new OcrResult.PageText();
                    pt.setImageIndex(item.path("imageIndex").asInt(pages.size()));
                    pt.setPageText(item.path("pageText").asText(""));
                    pages.add(pt);
                }
                result.setPages(pages);

                List<Integer> order = new ArrayList<>();
                JsonNode orderNode = json.path("suggestedOrder");
                if (orderNode.isArray()) {
                    for (JsonNode n : orderNode) {
                        if (n.isInt()) order.add(n.asInt());
                    }
                }
                result.setSuggestedOrder(order);
                return result;
            }

            result.setMode(OcrResult.OcrMode.MULTI_PROBLEM);
            List<DetectedText> list = new ArrayList<>();
            JsonNode array = json.path("detectedTexts");
            if (array.isArray()) {
                for (JsonNode item : array) {
                    list.add(mapToDetectedText(item));
                }
            } else {
                list.add(mapToDetectedText(json));
            }
            // 안전망: 지문 안내문/지문만 있는 블록은 "버리지 말고" 실제 문제에 합친다(지문 손실 방지).
            List<DetectedText> merged = mergePassageOnly(list);
            // 보정: 묶음([14~17])의 지문 이미지가 다른 장에 있는 문제(16·17)에도 붙도록 이미지 인덱스를 잇는다.
            linkPassageGroups(merged);
            result.setDetectedTexts(merged);
            return result;

        } catch (Exception e) {
            // 모델 출력이 잘리거나 형식이 깨지면 여기로 옴 → 사용자에게 알아들을 메시지
            throw BusinessException.internalError(
                    "문제 인식 결과 처리에 실패했어요. 사진을 더 적게/선명하게 올려 다시 시도해 주세요.", e);
        }
    }

    /**
     * 지문(묶음)이 여러 장에 걸친 경우 이미지 인덱스 보정.
     *
     * <p>OCR은 같은 지문을 그 묶음의 각 문제 extractedText 앞부분에 똑같이 복사해 넣는다.
     * 그래서 "지문 앞부분이 같은 문제들 = 같은 지문 묶음"으로 본다(특정 문제 번호에 의존하지 않는 일반 규칙).
     *
     * <p>지문은 보통 묶음의 가장 앞 장에 있으므로, 그룹이 걸친 이미지 중 '가장 앞 장'을 지문 장으로 보고
     * 그룹의 모든 문제 imageIndices에 추가한다. → 다른 장에 있는 문제를 골라도 지문 장이 함께 저장된다.
     * (예: 지문+14가 0장, 15·16·17이 1장 → 14는 [0] 유지, 15·16·17은 [0,1])
     */
    private void linkPassageGroups(List<DetectedText> list) {
        // 지문 앞부분(공백 제거 후 앞 40자)으로 그룹핑. 지문이 없는 짧은 단문 문제는 묶지 않는다.
        final int prefixLen = 40;
        Map<String, List<DetectedText>> groups = new LinkedHashMap<>();
        for (DetectedText t : list) {
            String text = t.getExtractedText();
            if (text == null) continue;
            String compact = text.replaceAll("\\s+", "");
            if (compact.length() < prefixLen) continue; // 지문 없는 단문은 제외
            String key = compact.substring(0, prefixLen);
            groups.computeIfAbsent(key, k -> new ArrayList<>()).add(t);
        }
        for (List<DetectedText> group : groups.values()) {
            if (group.size() < 2) continue; // 지문 공유 문제가 2개 이상일 때만 보정
            // 지문 장 = 그룹이 걸친 이미지 중 가장 앞 장
            int passageImg = Integer.MAX_VALUE;
            for (DetectedText t : group) {
                if (t.getImageIndices() == null) continue;
                for (Integer idx : t.getImageIndices()) passageImg = Math.min(passageImg, idx);
            }
            if (passageImg == Integer.MAX_VALUE) continue;
            for (DetectedText t : group) {
                List<Integer> idxs = t.getImageIndices();
                if (idxs == null) {
                    idxs = new ArrayList<>();
                    t.setImageIndices(idxs);
                }
                if (!idxs.contains(passageImg)) {
                    idxs.add(passageImg);
                    Collections.sort(idxs);
                }
            }
        }
    }

    /**
     * 지문/안내문만 있는 블록을 "버리지 않고" 실제 문제에 합친다(지문 손실 방지).
     * - "…물음에 답하시오" 같은 안내문 + 지문만 있고 발문/선택지 신호가 없는 블록 = 지문 블록.
     * - 지문 블록의 텍스트를 각 실제 문제 앞에 붙이고, 지문 이미지(장)도 그 문제의 imageIndices에 합친다.
     *   → 학생이 문제를 선택할 때 지문 페이지가 같이 보존되고(이미지 안 지워짐), 본문에도 지문이 남는다.
     * - 실제 문제가 하나도 없으면(지문만 업로드) 데이터 손실 방지를 위해 원본 그대로 둔다.
     */
    private List<DetectedText> mergePassageOnly(List<DetectedText> list) {
        List<DetectedText> passages = new ArrayList<>();
        List<DetectedText> reals = new ArrayList<>();
        for (DetectedText t : list) {
            if (isInstructionOnly(t.getExtractedText())) {
                passages.add(t);
            } else {
                reals.add(t);
            }
        }
        if (passages.isEmpty() || reals.isEmpty()) {
            return list; // 합칠 대상이 없거나 지문만 있음 → 그대로(버리지 않음)
        }

        // 지문 텍스트/이미지 모으기
        StringBuilder pb = new StringBuilder();
        List<Integer> passageImages = new ArrayList<>();
        for (DetectedText p : passages) {
            String s = p.getExtractedText() == null ? "" : p.getExtractedText().strip();
            if (!s.isBlank()) {
                if (pb.length() > 0) pb.append("\n\n");
                pb.append(s);
            }
            if (p.getImageIndices() != null) {
                for (Integer idx : p.getImageIndices()) {
                    if (!passageImages.contains(idx)) passageImages.add(idx);
                }
            }
        }
        String passageText = pb.toString();
        String head = passageText.length() > 20 ? passageText.substring(0, 20) : passageText;

        for (DetectedText r : reals) {
            String body = r.getExtractedText() == null ? "" : r.getExtractedText();
            // 이미 지문을 포함한 문제면 중복 방지
            if (!passageText.isBlank() && !body.contains(head)) {
                r.setExtractedText(passageText + "\n\n" + body);
            }
            // 지문 페이지를 이 문제에 포함 → 선택 시 지문 이미지가 보존됨
            if (!passageImages.isEmpty()) {
                List<Integer> merged = new ArrayList<>(passageImages);
                if (r.getImageIndices() != null) {
                    for (Integer idx : r.getImageIndices()) {
                        if (!merged.contains(idx)) merged.add(idx);
                    }
                }
                java.util.Collections.sort(merged); // 업로드 순서대로
                r.setImageIndices(merged);
            }
        }
        log.info("지문 블록 {}개를 실제 문제 {}개에 병합", passages.size(), reals.size());
        return reals;
    }

    /** 안내문("물음에 답하시오") 보일러플레이트만 있고, 실제 문제 신호가 하나도 없으면 true. */
    private boolean isInstructionOnly(String text) {
        if (text == null || text.isBlank()) return false;
        String compact = text.replaceAll("\\s+", "");
        boolean hasInstruction = compact.contains("물음에답하시오");
        if (!hasInstruction) return false;
        boolean hasChoice = text.matches("(?s).*[①②③④⑤⑥].*");       // 객관식 선택지
        boolean hasQuestionMark = text.contains("?") || text.contains("？");
        boolean hasStem = compact.contains("구하시오") || compact.contains("고르시오")
                || compact.contains("쓰시오") || compact.contains("서술하시오")
                || compact.contains("나타내시오") || compact.contains("구하라");
        return !(hasChoice || hasQuestionMark || hasStem);
    }

    private DetectedText mapToDetectedText(JsonNode node) {
        DetectedText t = new DetectedText();
        t.setExtractedText(node.path("extractedText").asText(""));

        String examCode = node.path("examCode").asText(null);
        t.setExamCode((examCode == null || examCode.isBlank() || "null".equalsIgnoreCase(examCode))
                ? null : examCode);

        JsonNode numNode = node.path("problemNumber");
        t.setProblemNumber(numNode.isInt() ? numNode.asInt() : null);

        List<Integer> indices = new ArrayList<>();
        JsonNode idxArr = node.path("imageIndices");
        if (idxArr.isArray()) {
            for (JsonNode n : idxArr) {
                if (n.isInt()) indices.add(n.asInt());
            }
        } else if (node.path("imageIndex").isInt()) {
            indices.add(node.path("imageIndex").asInt()); // 하위호환(단일)
        }
        t.setImageIndices(indices);

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