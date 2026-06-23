package com.ieum.backend.domain.review.service;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.review.dto.request.CreateReviewRequest;
import com.ieum.backend.domain.review.dto.response.ReviewSummaryResponse;
import com.ieum.backend.domain.review.repository.ReviewRepository;
import com.ieum.backend.global.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("리뷰 서비스")
class ReviewServiceTest {

    @Autowired ReviewService reviewService;
    @Autowired ReviewRepository reviewRepository;
    @Autowired LessonRepository lessonRepository;

    private static final long STUDENT_ID = 4100L;
    private static final long TUTOR_ID = 4200L;

    @BeforeEach
    void setUp() {
        reviewRepository.deleteAll();
        lessonRepository.deleteAll();
    }

    /** COMPLETED 상태 + studentId/tutorId가 박힌 강의 생성 */
    private Long completedLesson(long studentId, long tutorId, String channel) {
        Lesson lesson = new Lesson(channel);
        lesson.startBilling(studentId, tutorId, 50, LocalDateTime.now().plusMinutes(30));
        lesson.complete(null);
        return lessonRepository.save(lesson).getId();
    }

    @Test
    @DisplayName("완료된 본인 강의에 리뷰 작성 성공")
    void create_success() {
        Long lessonId = completedLesson(STUDENT_ID, TUTOR_ID, "ch-1");

        var res = reviewService.create(STUDENT_ID,
                new CreateReviewRequest(lessonId, 5, "좋았어요"));

        assertThat(res.tutorId()).isEqualTo(TUTOR_ID);
        assertThat(res.rating()).isEqualTo(5);
        assertThat(reviewRepository.existsByLessonId(lessonId)).isTrue();
    }

    @Test
    @DisplayName("같은 강의에 두 번 리뷰하면 거부(UNIQUE)")
    void create_duplicate_rejected() {
        Long lessonId = completedLesson(STUDENT_ID, TUTOR_ID, "ch-2");
        reviewService.create(STUDENT_ID, new CreateReviewRequest(lessonId, 5, "1차"));

        assertThatThrownBy(() ->
                reviewService.create(STUDENT_ID, new CreateReviewRequest(lessonId, 4, "2차")))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    @DisplayName("완료되지 않은 강의는 리뷰 불가")
    void create_notCompleted_rejected() {
        Lesson lesson = new Lesson("ch-3");
        lesson.startBilling(STUDENT_ID, TUTOR_ID, 50, LocalDateTime.now().plusMinutes(30)); // ACTIVE
        Long lessonId = lessonRepository.save(lesson).getId();

        assertThatThrownBy(() ->
                reviewService.create(STUDENT_ID, new CreateReviewRequest(lessonId, 5, null)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    @DisplayName("본인 강의가 아니면 리뷰 불가")
    void create_notOwner_rejected() {
        Long lessonId = completedLesson(STUDENT_ID, TUTOR_ID, "ch-4");

        assertThatThrownBy(() ->
                reviewService.create(9999L, new CreateReviewRequest(lessonId, 5, null)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    @DisplayName("튜터 리뷰 요약: 평균·개수·별점분포 집계")
    void summary_aggregates() {
        // 같은 튜터, 서로 다른 학생/강의로 별점 5,3,4
        reviewService.create(101L, new CreateReviewRequest(completedLesson(101L, TUTOR_ID, "c5"), 5, null));
        reviewService.create(102L, new CreateReviewRequest(completedLesson(102L, TUTOR_ID, "c6"), 3, null));
        reviewService.create(103L, new CreateReviewRequest(completedLesson(103L, TUTOR_ID, "c7"), 4, null));

        ReviewSummaryResponse summary = reviewService.getSummary(TUTOR_ID);

        assertThat(summary.totalCount()).isEqualTo(3);
        assertThat(summary.averageRating()).isEqualTo(4.0);   // (5+3+4)/3
        assertThat(summary.distribution().get(5)).isEqualTo(1);
        assertThat(summary.distribution().get(4)).isEqualTo(1);
        assertThat(summary.distribution().get(3)).isEqualTo(1);
        assertThat(summary.distribution().get(1)).isEqualTo(0);
    }
}
