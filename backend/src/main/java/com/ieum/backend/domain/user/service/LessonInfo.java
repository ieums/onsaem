package com.ieum.backend.domain.user.service;

import java.time.LocalDateTime;

/**
 * lessons 테이블의 한 행을 담는 읽기 모델.
 * lessons는 다른 팀원 소유 테이블이라 Lesson 엔티티에 직접 의존하지 않기 위해 별도 record로 둠.
 * (problems → ProblemContext와 같은 패턴)
 */
public record LessonInfo(
        Long lessonId,
        Long tutorId,
        Long studentId,
        String channelName,
        String status,           // WAITING / ACTIVE / COMPLETED
        String recordingUrl,     // S3 mp4 URL
        LocalDateTime startedAt,
        LocalDateTime endedAt
) {
}