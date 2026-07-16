package com.ieum.backend.domain.auth.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 인증 수단. LOCAL = 이메일/비밀번호, 나머지는 소셜 로그인. */
@Getter
@RequiredArgsConstructor
public enum AuthProvider {
    LOCAL("이메일"),
    GOOGLE("구글"),
    NAVER("네이버"),
    KAKAO("카카오");

    private final String displayName;
}
