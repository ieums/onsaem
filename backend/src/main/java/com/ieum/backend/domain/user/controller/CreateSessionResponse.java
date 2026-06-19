package com.ieum.backend.domain.user.controller;

import java.time.LocalDateTime;

public record CreateSessionResponse(
        Long sessionId,
        Long problemId,
        String title,
        String status,
        LocalDateTime createdAt
) {
}