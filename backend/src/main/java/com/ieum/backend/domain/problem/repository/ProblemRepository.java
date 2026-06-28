package com.ieum.backend.domain.problem.repository;

import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface ProblemRepository extends JpaRepository<Problem, Long> {

    @Query("SELECT p FROM Problem p WHERE p.searching = true AND p.searchDeadline > :now")
    List<Problem> findAllSearching(@Param("now") LocalDateTime now);

    @Query("SELECT p FROM Problem p WHERE p.searching = true AND p.expiringSoonNotified = false AND p.searchDeadline BETWEEN :from AND :to")
    List<Problem> findAllExpiringSoon(@Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    @Query("SELECT p FROM Problem p WHERE p.searching = true AND p.searchDeadline < :now")
    List<Problem> findAllExpired(@Param("now") LocalDateTime now);

    List<Problem> findAllByStudentId(Long studentId);

    // 학생의 모든 질문(상태 무관) — 마이페이지 '내 질문' 전체 목록(최신순).
    List<Problem> findAllByStudentIdOrderByCreatedAtDesc(Long studentId);

    List<Problem> findAllByStudentIdAndStatus(Long studentId, ProblemStatus status);

    // 학생이 현재 '탐색 중(매칭 대기)'인 질문 수 — 동시 등록 개수 제한에 사용.
    long countByStudentIdAndStatus(Long studentId, ProblemStatus status);

    @Query("SELECT p FROM Problem p WHERE p.id IN :problemIds")
    List<Problem> findAllByIdIn(@Param("problemIds") List<Long> problemIds);

    @Query("SELECT p FROM Problem p WHERE p.searching = true AND p.searchDeadline > :now AND p.subject IN :subjects")
    List<Problem> findAllSearchingBySubjects(@Param("now") LocalDateTime now, @Param("subjects") List<Subject> subjects);
}
