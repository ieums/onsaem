package com.ieum.backend.domain.user.service;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.ieum.backend.domain.user.entity.AiTutorMessage;
import com.ieum.backend.domain.user.entity.AiTutorMessageRole;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.util.List;

@Component
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
     * @param systemInstruction GeminiPromptBuilder가 만든 시스템 지시문
     * @param history           세션의 전체 메시지 (마지막에 방금 받은 학생 메시지 포함)
     * @return AI 튜터 응답 텍스트
     */
    public String generate(String systemInstruction, List<AiTutorMessage> history) {
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

        GeminiResponse response;
        try {
            response = restClient.post()
                    .uri("/models/{model}:generateContent", properties.model())
                    .header("x-goog-api-key", properties.apiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(GeminiResponse.class);
        } catch (RestClientException e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY, "AI 튜터 응답 생성에 실패했습니다.", e);
        }

        return extractText(response);
    }

    private String extractText(GeminiResponse response) {
        if (response == null || response.candidates() == null || response.candidates().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY, "AI 튜터가 응답을 생성하지 못했습니다.");
        }
        Content content = response.candidates().get(0).content();
        if (content == null || content.parts() == null || content.parts().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY, "AI 튜터가 응답을 생성하지 못했습니다.");
        }
        return content.parts().get(0).text();
    }

    // --- Gemini API JSON 매핑 ---

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