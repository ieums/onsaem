package com.ieum.backend.domain.auth.oauth;

import com.ieum.backend.domain.auth.entity.AuthProvider;

/** 소셜 플랫폼에서 추출한 사용자 정보 (provider별 응답을 공통 형태로 정규화). */
public record OAuthUserInfo(
        AuthProvider provider,
        String providerUserId,
        String email,             // 카카오 등 미동의 시 null 가능
        String name,
        String profileImageUrl
) {
}