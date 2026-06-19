package com.ieum.backend.domain.user.repository;

import com.ieum.backend.domain.user.entity.LessonReviewMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LessonReviewMessageRepository extends JpaRepository<LessonReviewMessage, Long> {

    List<LessonReviewMessage> findBySessionIdOrderByIdAsc(Long sessionId);
}