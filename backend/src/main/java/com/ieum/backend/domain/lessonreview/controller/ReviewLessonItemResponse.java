package com.ieum.backend.domain.lessonreview.controller;

import java.time.LocalDateTime;

/**
 * 복습 목록 아이템 (완료된 강의 1건).
 * - ready=false  → 전사/요약 처리 중 ("복습 준비중"으로 표시, 진입 불가)
 * - ready=true   → 복습 진입 가능. sessionId가 있으면 기존 세션, null이면 진입 시 생성.
 */
public record ReviewLessonItemResponse(
        Long lessonId,
        String title,
        boolean ready,
        String status,        // READY | PREPARING
        Long sessionId,       // 이미 만들어진 세션이 있으면 그 id, 없으면 null
        LocalDateTime endedAt,
        String subject,
        String imageUrl
) {
}
