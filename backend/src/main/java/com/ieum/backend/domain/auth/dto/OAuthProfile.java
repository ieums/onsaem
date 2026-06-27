package com.ieum.backend.domain.auth.dto;

/** 신규 소셜 사용자 가입 폼 프리필용 정보 (check 에서 registered=false 일 때 반환). */
public record OAuthProfile(
        String email,            // 카카오 등 미동의 시 null 가능
        String name,
        String profileImageUrl
) {
}