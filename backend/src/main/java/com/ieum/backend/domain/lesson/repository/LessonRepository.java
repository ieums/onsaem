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
}
