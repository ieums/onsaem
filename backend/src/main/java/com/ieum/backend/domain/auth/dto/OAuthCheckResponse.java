package com.ieum.backend.domain.auth.dto;

/**
 * 소셜 로그인 1단계 응답.
 * - registered=true  → tokens 채워짐(바로 로그인 완료), profile=null
 * - registered=false → profile 채워짐(가입 폼 프리필), tokens=null
 */
public record OAuthCheckResponse(
        boolean registered,
        TokenResponse tokens,
        OAuthProfile profile
) {
    public static OAuthCheckResponse loggedIn(TokenResponse tokens) {
        return new OAuthCheckResponse(true, tokens, null);
    }

    public static OAuthCheckResponse needsSignup(OAuthProfile profile) {
        return new OAuthCheckResponse(false, null, profile);
    }
}
