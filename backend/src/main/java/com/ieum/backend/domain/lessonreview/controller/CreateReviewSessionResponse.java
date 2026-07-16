package com.ieum.backend.domain.lessonreview.controller;

import java.time.LocalDateTime;

public record CreateReviewSessionResponse(
        Long sessionId,
        Long lessonId,
        String title,
        String status,
        LocalDateTime createdAt
) {
}