package com.ieum.backend.domain.user.entity;

/**
 * 강의 전사 처리 상태.
 * PENDING → PROCESSING → COMPLETED (정상) 또는 → FAILED (실패, 재시도 대상)
 */
public enum LessonTranscriptStatus {

    /** 처리 대기 */
    PENDING,

    /** 전사 진행 중 */
    PROCESSING,

    /** 전사 완료 */
    COMPLETED,

    /** 전사 실패 (다음 폴링에서 재시도 가능) */
    FAILED
}