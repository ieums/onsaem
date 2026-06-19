package com.ieum.backend.domain.user.controller;

import java.time.LocalDateTime;

public record ReviewMessageItemResponse(
        Long messageId,
        String role,           // "USER" or "AI"
        String content,
        LocalDateTime createdAt
) {
}