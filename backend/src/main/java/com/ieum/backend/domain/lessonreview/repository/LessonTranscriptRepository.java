package com.ieum.backend.domain.lessonreview.repository;

import com.ieum.backend.domain.lessonreview.entity.LessonTranscript;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface LessonTranscriptRepository extends JpaRepository<LessonTranscript, Long> {

    // lesson 1개당 트랜스크립트는 1개 (lesson_id UNIQUE)
    Optional<LessonTranscript> findByLessonId(Long lessonId);

    // 복습 목록: 여러 강의의 전사 상태를 한 번에 조회
    List<LessonTranscript> findByLessonIdIn(List<Long> lessonIds);

    /**
     * PDF 처리 대상 강의 ID 목록.
     * (4가지 조건 다 충족 시만 — 자세한 건 위 주석)
     */
    @Query(value = """
            SELECT t.lesson_id
            FROM lesson_transcript t
            JOIN lessons l ON l.id = t.lesson_id
            WHERE t.status = 'COMPLETED'
              AND (t.summary_pdf_status IS NULL OR t.summary_pdf_status NOT IN ('COMPLETED', 'PROCESSING'))
              AND l.problem_id IS NOT NULL
              AND EXISTS (
                  SELECT 1 FROM problem_images pi WHERE pi.problem_id = l.problem_id
              )
            """, nativeQuery = true)
    List<Long> findLessonIdsNeedingSummaryPdf();
}