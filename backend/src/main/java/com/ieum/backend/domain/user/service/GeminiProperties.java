package com.ieum.backend.domain.user.service;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

@ConfigurationProperties(prefix = "gemini")
public record GeminiProperties(
        Api api,                                                                          // ← 변경: String apiKey → Api api
        @DefaultValue("gemini-2.5-flash") String model,
        @DefaultValue("gemini-flash-latest") String fallbackModel,
        @DefaultValue("https://generativelanguage.googleapis.com/v1beta") String baseUrl,
        @DefaultValue("30") int timeoutSeconds,
        @DefaultValue("2") int maxRetries,
        @DefaultValue("1000") long retryDelayMs
) {
    public record Api(String key) {                                                       // ← 추가: 중첩 record
    }
}