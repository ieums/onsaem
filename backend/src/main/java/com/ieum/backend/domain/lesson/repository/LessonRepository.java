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

    // ── 관리자 콘솔(강의/매칭 관리 · 통계) ──
    List<Lesson> findTop300ByOrderByCreatedAtDesc();

    List<Lesson> findTop300ByStatusOrderByCreatedAtDesc(Lesson.LessonStatus status);

    /** 관리자 강의 목록 — 페이지 슬라이스(최신순). */
    org.springframework.data.domain.Page<Lesson> findAllByOrderByCreatedAtDesc(
            org.springframework.data.domain.Pageable pageable);

    org.springframework.data.domain.Page<Lesson> findByStatusOrderByCreatedAtDesc(
            Lesson.LessonStatus status, org.springframework.data.domain.Pageable pageable);

    long countByStatus(Lesson.LessonStatus status);

    // 완료 강의 평균 수업시간(분) — startedAt/endedAt 모두 있는 건만. 데이터 없으면 null.
    // JPQL의 avg(timestampdiff(...))는 Hibernate가 인자 타입(Object)을 못 받아 기동 시 검증 실패 → 네이티브 쿼리.
    // status 컬럼은 EnumType.STRING 저장이라 String("COMPLETED")으로 바인딩한다.
    @org.springframework.data.jpa.repository.Query(value = """
            select avg(timestampdiff(minute, started_at, ended_at))
            from lessons
            where status = :status
              and started_at is not null
              and ended_at is not null
            """, nativeQuery = true)
    Double avgDurationMinutes(@org.springframework.data.repository.query.Param("status") String status);
}
