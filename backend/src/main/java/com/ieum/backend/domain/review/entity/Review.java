package com.ieum.backend.domain.review.entity;

import com.ieum.backend.domain.review.entity.enums.ReviewStatus;
import com.ieum.backend.global.exception.BusinessException;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 튜터 평점·후기 리뷰.
 * 강의 1건당 학생→튜터 리뷰 1개 (lesson_id UNIQUE).
 * student_id·tutor_id는 타 도메인 디커플링 위해 Long 컬럼.
 */
@Entity
@Table(
        name = "reviews",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_reviews_lesson_id",
                columnNames = "lesson_id"
        )
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Review {

    public static final int MIN_RATING = 1;
    public static final int MAX_RATING = 5;
    public static final int MAX_COMMENT_LENGTH = 500;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "lesson_id", nullable = false)
    private Long lessonId;

    @Column(name = "student_id", nullable = false)
    private Long studentId;

    @Column(name = "tutor_id", nullable = false)
    private Long tutorId;

    @Column(nullable = false)
    private Integer rating;            // 1~5

    @Column(length = MAX_COMMENT_LENGTH)
    private String comment;            // 선택

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private ReviewStatus status;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @Builder
    public Review(Long lessonId, Long studentId, Long tutorId, Integer rating, String comment) {
        validateRating(rating);
        this.lessonId = lessonId;
        this.studentId = studentId;
        this.tutorId = tutorId;
        this.rating = rating;
        this.comment = comment;
        this.status = ReviewStatus.VISIBLE;
        this.createdAt = LocalDateTime.now();
    }

    /** 리뷰 수정 (작성자) */
    public void update(Integer rating, String comment) {
        if (rating != null) {
            validateRating(rating);
            this.rating = rating;
        }
        if (comment != null) {
            this.comment = comment;
        }
        this.updatedAt = LocalDateTime.now();
    }

    /** 신고 처리 등으로 숨김 */
    public void hide() {
        this.status = ReviewStatus.HIDDEN;
        this.updatedAt = LocalDateTime.now();
    }

    private static void validateRating(Integer rating) {
        if (rating == null || rating < MIN_RATING || rating > MAX_RATING) {
            throw BusinessException.badRequest(
                    "별점은 " + MIN_RATING + "~" + MAX_RATING + " 사이여야 합니다. 입력: " + rating);
        }
    }
}
