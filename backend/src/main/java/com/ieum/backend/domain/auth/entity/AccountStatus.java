package com.ieum.backend.domain.auth.entity;

/** 계정 상태. */
public enum AccountStatus {
    /** 정상 활동 */
    ACTIVE,
    /** 휴면/비활성 */
    INACTIVE,
    /** 운영자 제재 */
    SUSPENDED,
    /** 탈퇴 — 행은 남고 개인정보는 파기된 상태 (soft delete) */
    WITHDRAWN
}