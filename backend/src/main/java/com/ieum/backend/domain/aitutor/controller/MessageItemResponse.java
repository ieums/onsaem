package com.ieum.backend.domain.aitutor.controller;

import java.time.LocalDateTime;

public record MessageItemResponse(
        Long messageId,
        String role,        // "USER" or "AI"
        String content,
        LocalDateTime createdAt
) {
}