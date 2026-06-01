package com.ieum.backend.domain.user.entity;

/**
 * 강의 복습 세션 상태.
 */
public enum LessonReviewSessionStatus {

    /** 대화가 진행 중인 세션 */
    ACTIVE,

    /** 학생이 종료했거나 더 이상 사용하지 않는 세션 */
    CLOSED
}