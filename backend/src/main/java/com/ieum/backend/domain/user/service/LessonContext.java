package com.ieum.backend.domain.user.service;

import java.time.LocalDateTime;

/**
 * 복습 챗봇 시스템 프롬프트 조립에 필요한 강의 정보.
 * LessonInfo + LessonTranscript 합쳐서 만듦.
 */
public record LessonContext(
        Long lessonId,
        Long tutorId,
        LocalDateTime startedAt,
        LocalDateTime endedAt,
        String transcript,
        String summary
) {
}