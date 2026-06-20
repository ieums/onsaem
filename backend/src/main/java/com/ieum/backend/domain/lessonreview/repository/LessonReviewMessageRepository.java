package com.ieum.backend.domain.lessonreview.repository;

import com.ieum.backend.domain.lessonreview.entity.LessonReviewMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LessonReviewMessageRepository extends JpaRepository<LessonReviewMessage, Long> {

    List<LessonReviewMessage> findBySessionIdOrderByIdAsc(Long sessionId);
}