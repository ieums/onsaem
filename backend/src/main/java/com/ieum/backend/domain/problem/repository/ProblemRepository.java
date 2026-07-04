package com.ieum.backend.domain.problem.repository;

import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

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

    /**
     * 매칭 확정용 — 문제 행에 쓰기 락을 걸어 '한 문제 = 한 번만 매칭'을 보장한다.
     * 서로 다른 강사의 확정이 동시에 들어와도 이 락으로 직렬화되어, 뒤늦은 확정은 이미
     * MATCHED 상태를 읽고 거부되므로 한 문제에 Lesson이 2개 생기지 않는다.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT p FROM Problem p WHERE p.id = :id")
    Optional<Problem> findByIdForUpdate(@Param("id") Long id);
}
