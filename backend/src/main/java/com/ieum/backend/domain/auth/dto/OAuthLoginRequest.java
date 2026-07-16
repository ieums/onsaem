package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.NotBlank;

/** 소셜 로그인 요청. role = "student"|"tutor", token = 프론트 SDK가 받은 idToken/accessToken */
public record OAuthLoginRequest(
        @NotBlank String role,
        @NotBlank String token
) {
}