package com.ieum.backend.domain.aitutor.entity;

/**
 * AI 튜터 챗봇 세션의 상태.
 */
public enum AiTutorSessionStatus {

    /** 대화가 진행 중인 세션 */
    ACTIVE,

    /** 학생이 종료했거나 더 이상 사용하지 않는 세션 */
    CLOSED
}
