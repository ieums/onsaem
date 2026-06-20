package com.ieum.backend.domain.aitutor.service;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.ieum.backend.domain.aitutor.entity.AiTutorMessage;
import com.ieum.backend.domain.aitutor.entity.AiTutorMessageRole;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.time.Duration;
import java.util.List;


@Slf4j
@Component("aiTutorGeminiClient")
@EnableConfigurationProperties(GeminiProperties.class)
public class GeminiClient {

    private final GeminiProperties properties;
    private final RestClient restClient;

    public GeminiClient(GeminiProperties properties) {
        this.properties = properties;

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(10));
        factory.setReadTimeout(Duration.ofSeconds(properties.timeoutSeconds()));

        this.restClient = RestClient.builder()
                .baseUrl(properties.baseUrl())
                .requestFactory(factory)
                .build();
    }

    /**
     * Gemini 호출. 실패 시 재시도 → fallback 모델 순서로 시도.
     * 끝까지 실패하면 RestClientException 그대로 던진다 (서비스 단에서 catch).
     */
    public String generate(String systemInstruction, List<AiTutorMessage> history) {
        // 1차: 기본 모델 + 재시도
        try {
            return callWithRetry(properties.model(), systemInstruction, history);
        } catch (RestClientException primaryError) {
            log.warn("기본 모델 '{}' 호출 최종 실패. fallback 모델 '{}' 로 시도합니다.",
                    properties.model(), properties.fallbackModel(), primaryError);
        }

        // 2차: fallback 모델 (1회만 시도)
        return callOnce(properties.fallbackModel(), systemInstruction, history);
    }

    private String callWithRetry(String model, String systemInstruction, List<AiTutorMessage> history) {
        RestClientException lastError = null;
        int totalAttempts = properties.maxRetries() + 1;
        for (int attempt = 1; attempt <= totalAttempts; attempt++) {
            try {
                return callOnce(model, systemInstruction, history);
            } catch (RestClientException e) {
                lastError = e;
                if (attempt >= totalAttempts) break;
                long delay = properties.retryDelayMs() * (long) Math.pow(2, attempt - 1);
                log.warn("Gemini 호출 실패 (시도 {}/{}, 모델={}). {}ms 후 재시도",
                        attempt, totalAttempts, model, delay);
                sleep(delay);
            }
        }
        throw lastError;
    }

    private String callOnce(String model, String systemInstruction, List<AiTutorMessage> history) {
        List<Content> contents = history.stream()
                .map(m -> new Content(
                        m.getRole() == AiTutorMessageRole.USER ? "user" : "model",
                        List.of(new Part(m.getContent()))))
                .toList();

        GeminiRequest request = new GeminiRequest(
                new Content(null, List.of(new Part(systemInstruction))),
                contents,
                new GenerationConfig(0.7, 2048)
        );

        GeminiResponse response = restClient.post()
                .uri("/models/{model}:generateContent", model)
                .header("x-goog-api-key", properties.api().key())
                .contentType(MediaType.APPLICATION_JSON)
                .body(request)
                .retrieve()
                .body(GeminiResponse.class);

        return extractText(response);
    }

    private String extractText(GeminiResponse response) {
        if (response == null || response.candidates() == null || response.candidates().isEmpty()) {
            throw new RestClientException("Gemini 응답에 candidates 없음");
        }
        Content content = response.candidates().get(0).content();
        if (content == null || content.parts() == null || content.parts().isEmpty()) {
            throw new RestClientException("Gemini 응답이 비어 있음");
        }
        return content.parts().get(0).text();
    }

    private void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("재시도 대기 중 인터럽트", e);
        }
    }



    private record GeminiRequest(
            Content systemInstruction,
            List<Content> contents,
            GenerationConfig generationConfig
    ) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Content(String role, List<Part> parts) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Part(String text) {
    }

    private record GenerationConfig(double temperature, int maxOutputTokens) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record GeminiResponse(List<Candidate> candidates) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Candidate(Content content, String finishReason) {
    }
}