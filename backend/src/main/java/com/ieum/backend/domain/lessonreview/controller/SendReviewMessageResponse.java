package com.ieum.backend.domain.lessonreview.controller;

import java.time.LocalDateTime;

public record SendReviewMessageResponse(
        Long messageId,
        String role,
        String content,
        LocalDateTime createdAt
) {
}