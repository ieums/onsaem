package com.ieum.backend.domain.auth.oauth;

import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

/** 소셜 OAuth 클라이언트 공통 — 타임아웃이 설정된 RestClient를 제공 */
public abstract class AbstractOAuthClient implements OAuthClient {

    private static final int TIMEOUT_MS = 5000;

    protected final RestClient restClient;

    protected AbstractOAuthClient() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(TIMEOUT_MS);
        factory.setReadTimeout(TIMEOUT_MS);
        this.restClient = RestClient.builder()
                .requestFactory(factory)
                .build();
    }
}