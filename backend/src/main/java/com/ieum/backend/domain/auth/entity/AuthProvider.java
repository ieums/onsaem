package com.ieum.backend.domain.auth.entity;

/** 인증 수단. LOCAL = 이메일/비밀번호, 나머지는 소셜 로그인. */
public enum AuthProvider {
    LOCAL,
    GOOGLE,
    NAVER,
    KAKAO
}