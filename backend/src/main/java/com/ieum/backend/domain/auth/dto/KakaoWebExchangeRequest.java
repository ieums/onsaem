package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.NotBlank;

/** 카카오 웹 로그인 — 인가코드(PKCE)를 액세스 토큰으로 교환하기 위한 요청 */
public record KakaoWebExchangeRequest(
        @NotBlank String code,
        @NotBlank String redirectUri,
        @NotBlank String codeVerifier
) {
}