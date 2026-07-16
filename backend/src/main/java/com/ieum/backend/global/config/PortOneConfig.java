package com.ieum.backend.global.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class PortOneConfig {

    @Value("${portone.api-secret}")
    private String apiSecret;

    @Value("${portone.api-base-url}")
    private String baseUrl;

    @Bean
    public RestClient portOneRestClient() {
        return RestClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Authorization", "PortOne " + apiSecret)
                .build();
    }
}