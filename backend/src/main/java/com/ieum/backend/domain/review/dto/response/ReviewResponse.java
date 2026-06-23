package com.ieum.backend.domain.review.dto.response;

import com.ieum.backend.domain.review.entity.Review;
import com.ieum.backend.domain.review.entity.enums.ReviewStatus;

import java.time.LocalDateTime;

public record ReviewResponse(
        Long id,
        Long lessonId,
        Long studentId,
        Long tutorId,
        Integer rating,
        String comment,
        ReviewStatus status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static ReviewResponse from(Review r) {
        return new ReviewResponse(
                r.getId(), r.getLessonId(), r.getStudentId(), r.getTutorId(),
                r.getRating(), r.getComment(), r.getStatus(),
                r.getCreatedAt(), r.getUpdatedAt()
        );
    }
}
