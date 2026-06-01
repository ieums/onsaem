package com.ieum.backend.domain.user.controller;

import java.time.LocalDateTime;

public record ReviewSessionListItemResponse(
        Long sessionId,
        Long lessonId,
        String title,
        String status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}