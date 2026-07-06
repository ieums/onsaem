package com.ieum.backend.domain.matching.repository;

import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface MatchingApplicationRepository extends JpaRepository<MatchingApplication, Long> {

    List<MatchingApplication> findByProblemIdAndStatusIn(Long problemId, List<ApplicationStatus> statuses);

    boolean existsByProblemIdAndTutorId(Long problemId, Long tutorId);

    List<MatchingApplication> findByTutorIdAndStatus(Long tutorId, ApplicationStatus status);

    List<MatchingApplication> findByProblemId(Long problemId);

    /** 그 문제의 모든 신청 기록 삭제 — '다시 요청'(reopen)으로 새 탐색 라운드를 시작할 때 사용. */
    long deleteByProblemId(Long problemId);

    Optional<MatchingApplication> findByProblemIdAndTutorId(Long problemId, Long tutorId);

    /**
     * 확정용 — 신청 행에 쓰기 락을 걸어 튜터·학생의 '동시 확인'을 직렬화한다.
     * 락이 없으면 둘 다 확인 플래그를 stale 상태로 읽어 갱신 유실(둘 다 미확정)이 날 수 있다.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from MatchingApplication a where a.problemId = :problemId and a.tutorId = :tutorId")
    Optional<MatchingApplication> findByProblemIdAndTutorIdForUpdate(Long problemId, Long tutorId);

    int countByProblemIdAndStatusIn(Long problemId, List<ApplicationStatus> statuses);

    List<MatchingApplication> findByTutorIdAndStatusIn(Long tutorId, List<ApplicationStatus> statuses);

    List<MatchingApplication> findByStatusAndConfirmedAtBefore(ApplicationStatus status, LocalDateTime cutoff);

    /** 학생이 아직 수락하지 않은(studentConfirmed=false) CONFIRMING 신청 — 앱 재실행 시 수락 복구용. */
    List<MatchingApplication> findByProblemIdInAndStatusAndStudentConfirmedFalse(
            List<Long> problemIds, ApplicationStatus status);
}
