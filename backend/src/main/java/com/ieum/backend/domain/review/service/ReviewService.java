package com.ieum.backend.domain.review.service;

import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.entity.Lesson.LessonStatus;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
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
    private final TutorRepository tutorRepository;      // 내 후기에 강사 이름 표시
    private final ProblemRepository problemRepository;  // 내 후기에 과목 표시

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
        refreshTutorRating(review.getTutorId());
        return ReviewResponse.from(review);
    }

    /**
     * 리뷰 수정 (작성자 본인).
     */
    @Transactional
    public ReviewResponse update(Long reviewId, Long studentId, UpdateReviewRequest request) {
        Review review = findOwnedReview(reviewId, studentId);
        review.update(request.getRating(), request.getComment());
        refreshTutorRating(review.getTutorId());
        return ReviewResponse.from(review);
    }

    /**
     * 리뷰 삭제 (작성자 본인).
     */
    @Transactional
    public void delete(Long reviewId, Long studentId) {
        Review review = findOwnedReview(reviewId, studentId);
        Long tutorId = review.getTutorId();
        reviewRepository.delete(review);
        refreshTutorRating(tutorId);
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
        List<Review> reviews = reviewRepository
                .findByStudentIdAndStatusOrderByCreatedAtDesc(studentId, ReviewStatus.VISIBLE);
        if (reviews.isEmpty()) return List.of();

        // 강사 이름 맵
        List<Long> tutorIds = reviews.stream().map(Review::getTutorId).distinct().toList();
        Map<Long, String> tutorNames = tutorRepository.findAllByIdIn(tutorIds).stream()
                .collect(java.util.stream.Collectors.toMap(Tutor::getId, Tutor::getName));

        // 과목: lesson → problemId → problem.subject
        List<Long> lessonIds = reviews.stream().map(Review::getLessonId).distinct().toList();
        Map<Long, Long> lessonToProblem = new java.util.HashMap<>();
        lessonRepository.findAllById(lessonIds).forEach(l -> {
            if (l.getProblemId() != null) lessonToProblem.put(l.getId(), l.getProblemId());
        });
        List<Long> problemIds = lessonToProblem.values().stream().distinct().toList();
        Map<Long, String> problemSubjects = problemRepository.findAllByIdIn(problemIds).stream()
                .collect(java.util.stream.Collectors.toMap(
                        Problem::getId,
                        p -> p.getSubject() != null ? p.getSubject().name() : null));

        return reviews.stream().map(r -> {
            String tutorName = tutorNames.get(r.getTutorId());
            Long pid = lessonToProblem.get(r.getLessonId());
            String subject = pid != null ? problemSubjects.get(pid) : null;
            return ReviewResponse.from(r, tutorName, subject);
        }).toList();
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
    /** 강사의 노출 리뷰로 평균·개수를 재계산해 강사 실적/등급에 반영. */
    private void refreshTutorRating(Long tutorId) {
        List<Object[]> rows =
                reviewRepository.ratingDistribution(tutorId, ReviewStatus.VISIBLE);
        long total = 0;
        long weighted = 0;
        for (Object[] row : rows) {
            int rating = ((Number) row[0]).intValue();
            long count = ((Number) row[1]).longValue();
            total += count;
            weighted += (long) rating * count;
        }
        final long t = total;
        final long w = weighted;
        tutorRepository.findById(tutorId).ifPresent(tutor -> {
            if (t == 0) {
                tutor.applyRating(null, 0);
            } else {
                double avg = Math.round((double) w / t * 10.0) / 10.0;
                tutor.applyRating(java.math.BigDecimal.valueOf(avg), (int) t);
            }
        });
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
