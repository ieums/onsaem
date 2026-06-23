package com.ieum.backend.domain.review.repository;

import com.ieum.backend.domain.review.entity.Review;
import com.ieum.backend.domain.review.entity.enums.ReviewStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    boolean existsByLessonId(Long lessonId);

    List<Review> findByTutorIdAndStatusOrderByCreatedAtDesc(Long tutorId, ReviewStatus status);

    /**
     * 튜터의 별점 분포 (별점별 개수) — DB 집계.
     * 평균·총개수는 이 결과로 서비스에서 계산(전체 로드 없이).
     */
    @Query("select r.rating, count(r) from Review r " +
            "where r.tutorId = :tutorId and r.status = :status group by r.rating")
    List<Object[]> ratingDistribution(@Param("tutorId") Long tutorId,
                                      @Param("status") ReviewStatus status);
}
