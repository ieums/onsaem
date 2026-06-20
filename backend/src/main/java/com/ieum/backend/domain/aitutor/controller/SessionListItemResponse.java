package com.ieum.backend.domain.aitutor.controller;

import java.time.LocalDateTime;

public record SessionListItemResponse(
        Long sessionId,
        Long problemId,
        String title,
        String status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}