package com.ieum.backend.domain.review.dto.response;

import com.ieum.backend.domain.review.entity.Review;
import com.ieum.backend.domain.review.entity.enums.ReviewStatus;

import java.time.LocalDateTime;

public record ReviewResponse(
        Long id,
        Long lessonId,
        Long studentId,
        Long tutorId,
        String tutorName,   // 내 후기 목록 표시용 (없으면 null)
        String subject,     // 강의 과목 enum name (KOREAN 등, 없으면 null)
        Integer rating,
        String comment,
        ReviewStatus status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static ReviewResponse from(Review r) {
        return from(r, null, null);
    }

    public static ReviewResponse from(Review r, String tutorName, String subject) {
        return new ReviewResponse(
                r.getId(), r.getLessonId(), r.getStudentId(), r.getTutorId(),
                tutorName, subject,
                r.getRating(), r.getComment(), r.getStatus(),
                r.getCreatedAt(), r.getUpdatedAt()
        );
    }
}
