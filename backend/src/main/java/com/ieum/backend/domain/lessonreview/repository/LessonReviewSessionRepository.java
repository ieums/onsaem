package com.ieum.backend.domain.lessonreview.repository;

import com.ieum.backend.domain.lessonreview.entity.LessonReviewSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LessonReviewSessionRepository extends JpaRepository<LessonReviewSession, Long> {

    // 소유권 검증을 겸한 단건 조회 (다른 학생 세션 접근 차단)
    Optional<LessonReviewSession> findByIdAndStudentId(Long id, Long studentId);

    // 학생의 세션 목록 — 최근 활동순
    List<LessonReviewSession> findByStudentIdOrderByUpdatedAtDesc(Long studentId);
}