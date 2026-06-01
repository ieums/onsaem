package com.ieum.backend.domain.user.controller;

import java.time.LocalDateTime;

public record CreateReviewSessionResponse(
        Long sessionId,
        Long lessonId,
        String title,
        String status,
        LocalDateTime createdAt
) {
}