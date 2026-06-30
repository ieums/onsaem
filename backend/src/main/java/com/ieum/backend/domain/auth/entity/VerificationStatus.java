package com.ieum.backend.domain.auth.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 강사 자격 검수 상태. */
@Getter
@RequiredArgsConstructor
public enum VerificationStatus {
    PENDING("대기"),
    VERIFIED("인증완료"),
    REJECTED("반려");

    private final String displayName;
}
