package com.ieum.backend.domain.auth.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 계정 상태. */
@Getter
@RequiredArgsConstructor
public enum AccountStatus {
    /** 정상 활동 */
    ACTIVE("활동중"),
    /** 휴면/비활성 */
    INACTIVE("휴면"),
    /** 운영자 제재 */
    SUSPENDED("정지"),
    /** 탈퇴 — 행은 남고 개인정보는 파기된 상태 (soft delete) */
    WITHDRAWN("탈퇴");

    private final String displayName;
}
