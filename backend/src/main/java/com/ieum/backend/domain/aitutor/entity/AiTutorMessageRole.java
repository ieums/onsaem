package com.ieum.backend.domain.aitutor.entity;

/**
 * AI 튜터 챗봇 메시지의 작성 주체.
 * Gemini API 호출 시에는 USER -> "user", AI -> "model" 로 변환
 */
public enum AiTutorMessageRole {

    /** 학생이 보낸 메시지 */
    USER,
    /** Gemini 기반 AI 튜터가 보낸 메시지 */
    AI
}
