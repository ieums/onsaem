package com.ieum.backend.domain.lessonreview.controller;

import jakarta.validation.constraints.NotNull;

public record CreateReviewSessionRequest(
        @NotNull(message = "lessonId는 필수입니다.") Long lessonId
) {
}