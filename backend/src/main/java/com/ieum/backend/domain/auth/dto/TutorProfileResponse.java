package com.ieum.backend.domain.auth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record TutorProfileResponse(
        Long id,
        String name,
        String profileImageUrl,
        String school,
        String major,
        String bio,
        List<String> subjects,
        BigDecimal ratingAvg,
        int reviewCount,
        int lessonCount,
        @JsonProperty("isAvailable") boolean available,
        List<ReviewItem> reviews
) {
    public record ReviewItem(
            Long id,
            int rating,
            String comment,
            LocalDateTime createdAt,
            String studentName
    ) {}
}
