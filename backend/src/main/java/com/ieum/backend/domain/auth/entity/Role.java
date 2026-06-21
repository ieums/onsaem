package com.ieum.backend.domain.auth.entity;

/** 인증 주체 역할. JWT 클레임·Spring Security 권한에 사용. */
public enum Role {
    STUDENT,
    TUTOR;

    /** Spring Security 권한 문자열 (ROLE_ 접두사 관례) */
    public String authority() {
        return "ROLE_" + name();
    }
}