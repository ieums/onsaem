package com.ieum.backend.domain.lesson.repository;

import com.ieum.backend.domain.lesson.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface LessonRepository extends JpaRepository<Lesson, Long> {
    Optional<Lesson> findByChannelName(String channelName);

    List<Lesson> findByStatusAndStartedAtBefore(Lesson.LessonStatus status, LocalDateTime threshold);

    List<Lesson> findByStatusAndCreatedAtBefore(Lesson.LessonStatus status, LocalDateTime threshold);

    boolean existsByTutorIdAndStatusIn(Long tutorId, java.util.Collection<Lesson.LessonStatus> statuses);

    // 정산 확정 대상: 완료된 과금 강의(coinCost 존재) 중 종료가 cutoff 이전
    List<Lesson> findByStatusAndCoinCostIsNotNullAndEndedAtBefore(
            Lesson.LessonStatus status, LocalDateTime threshold);

    // 강사의 완료된 과금 강의 전체(정산 예정 산출용 — 미정산 건은 서비스에서 걸러냄)
    List<Lesson> findByTutorIdAndStatusAndCoinCostIsNotNull(
            Long tutorId, Lesson.LessonStatus status);

    // 문제 id들로 연결된 강의 일괄 조회(복습 진입용 problemId→lessonId 매핑, N+1 회피)
    List<Lesson> findByProblemIdIn(java.util.Collection<Long> problemIds);
}
