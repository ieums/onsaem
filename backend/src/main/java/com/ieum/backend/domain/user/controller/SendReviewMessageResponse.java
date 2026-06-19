package com.ieum.backend.domain.user.controller;

import java.time.LocalDateTime;

public record SendReviewMessageResponse(
        Long messageId,
        String role,
        String content,
        LocalDateTime createdAt
) {
}