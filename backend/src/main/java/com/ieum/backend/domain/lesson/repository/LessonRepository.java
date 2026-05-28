package com.ieum.backend.domain.lesson.repository;

import com.ieum.backend.domain.lesson.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface LessonRepository extends JpaRepository<Lesson, Long> {
    Optional<Lesson> findByChannelName(String channelName);
}
