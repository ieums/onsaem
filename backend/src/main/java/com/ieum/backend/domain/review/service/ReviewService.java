package com.ieum.backend.domain.review.service;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.entity.Lesson.LessonStatus;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.review.dto.request.CreateReviewRequest;
import com.ieum.backend.domain.review.dto.request.UpdateReviewRequest;
import com.ieum.backend.domain.review.dto.response.ReviewResponse;
import com.ieum.backend.domain.review.dto.response.ReviewSummaryResponse;
import com.ieum.backend.domain.review.entity.Review;
import com.ieum.backend.domain.review.entity.enums.ReviewStatus;
import com.ieum.backend.domain.review.repository.ReviewRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final LessonRepository lessonRepository;   // 읽기 전용 참조

    /**
     * 리뷰 작성 — 완료된 강의 + 본인 강의 + 강의당 1개.
     */
    @Transactional
    public ReviewResponse create(Long studentId, CreateReviewRequest request) {
        Lesson lesson = lessonRepository.findById(request.getLessonId())
                .orElseThrow(() -> BusinessException.notFound("강의를 찾을 수 없습니다."));

        if (lesson.getStatus() != LessonStatus.COMPLETED) {
            throw BusinessException.badRequest("완료된 강의만 리뷰할 수 있습니다.");
        }
        if (!studentId.equals(lesson.getStudentId())) {
            throw BusinessException.forbidden("본인 강의만 리뷰할 수 있습니다.");
        }

        // 1차 방어 (친절한 에러)
        if (reviewRepository.existsByLessonId(lesson.getId())) {
            throw BusinessException.conflict("이미 작성한 리뷰가 있습니다.");
        }

        Review review = Review.builder()
                .lessonId(lesson.getId())
                .studentId(studentId)
                .tutorId(lesson.getTutorId())
                .rating(request.getRating())
                .comment(request.getComment())
                .build();

        // 2차 방어 (동시 작성도 lesson_id UNIQUE가 막음)
        try {
            reviewRepository.saveAndFlush(review);
        } catch (DataIntegrityViolationException e) {
            throw BusinessException.conflict("이미 작성한 리뷰가 있습니다.", e);
        }
        return ReviewResponse.from(review);
    }

    /**
     * 리뷰 수정 (작성자 본인).
     */
    @Transactional
    public ReviewResponse update(Long reviewId, Long studentId, UpdateReviewRequest request) {
        Review review = findOwnedReview(reviewId, studentId);
        review.update(request.getRating(), request.getComment());
        return ReviewResponse.from(review);
    }

    /**
     * 리뷰 삭제 (작성자 본인).
     */
    @Transactional
    public void delete(Long reviewId, Long studentId) {
        Review review = findOwnedReview(reviewId, studentId);
        reviewRepository.delete(review);
    }

    /**
     * 튜터 리뷰 목록 (노출 리뷰만, 최신순).
     */
    public List<ReviewResponse> getByTutor(Long tutorId) {
        return reviewRepository
                .findByTutorIdAndStatusOrderByCreatedAtDesc(tutorId, ReviewStatus.VISIBLE)
                .stream()
                .map(ReviewResponse::from)
                .toList();
    }

    /**
     * 내가(학생) 쓴 리뷰 목록 — 마이페이지 '내 리뷰 내역'.
     */
    public List<ReviewResponse> getMyReviews(Long studentId) {
        return reviewRepository
                .findByStudentIdAndStatusOrderByCreatedAtDesc(studentId, ReviewStatus.VISIBLE)
                .stream()
                .map(ReviewResponse::from)
                .toList();
    }

    /**
     * 튜터 리뷰 요약 (평균·총개수·별점분포) — DB 집계.
     */
    public ReviewSummaryResponse getSummary(Long tutorId) {
        List<Object[]> rows = reviewRepository.ratingDistribution(tutorId, ReviewStatus.VISIBLE);

        Map<Integer, Long> distribution = new LinkedHashMap<>();
        for (int star = Review.MIN_RATING; star <= Review.MAX_RATING; star++) {
            distribution.put(star, 0L);
        }

        long total = 0;
        long weightedSum = 0;
        for (Object[] row : rows) {
            int rating = ((Number) row[0]).intValue();
            long count = ((Number) row[1]).longValue();
            distribution.put(rating, count);
            total += count;
            weightedSum += (long) rating * count;
        }

        double average = total == 0 ? 0.0 : Math.round((double) weightedSum / total * 10.0) / 10.0;
        return new ReviewSummaryResponse(tutorId, average, total, distribution);
    }

    private Review findOwnedReview(Long reviewId, Long studentId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> BusinessException.notFound("리뷰를 찾을 수 없습니다."));
        if (!review.getStudentId().equals(studentId)) {
            throw BusinessException.forbidden("본인 리뷰만 수정·삭제할 수 있습니다.");
        }
        return review;
    }
}
