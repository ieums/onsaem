package com.ieum.backend.domain.lessonreview.entity;

/**
 * 강의 복습 메시지의 작성 주체.
 * Gemini 호출 시 USER → "user", AI → "model" 로 변환.
 */
public enum LessonReviewMessageRole {

    /** 학생이 보낸 메시지 */
    USER,

    /** AI 가 보낸 메시지 */
    AI
}