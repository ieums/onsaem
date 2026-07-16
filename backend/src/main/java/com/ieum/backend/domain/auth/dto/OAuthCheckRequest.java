package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.NotBlank;

/** 소셜 로그인 1단계 요청. token = 프론트 SDK가 받은 idToken/accessToken */
public record OAuthCheckRequest(
        @NotBlank String token
) {
}