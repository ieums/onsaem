package com.ieum.backend.domain.user.repository;

import com.ieum.backend.domain.user.entity.LessonTranscript;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface LessonTranscriptRepository extends JpaRepository<LessonTranscript, Long> {

    // lesson 1개당 트랜스크립트는 1개 (lesson_id UNIQUE)
    Optional<LessonTranscript> findByLessonId(Long lessonId);
}