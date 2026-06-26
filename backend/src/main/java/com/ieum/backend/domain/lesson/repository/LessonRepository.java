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
}
