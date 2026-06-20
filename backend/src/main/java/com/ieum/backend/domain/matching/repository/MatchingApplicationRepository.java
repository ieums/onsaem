package com.ieum.backend.domain.matching.repository;

import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface MatchingApplicationRepository extends JpaRepository<MatchingApplication, Long> {

    List<MatchingApplication> findByProblemIdAndStatusIn(Long problemId, List<ApplicationStatus> statuses);

    boolean existsByProblemIdAndTutorId(Long problemId, Long tutorId);

    List<MatchingApplication> findByTutorIdAndStatus(Long tutorId, ApplicationStatus status);

    List<MatchingApplication> findByProblemId(Long problemId);

    Optional<MatchingApplication> findByProblemIdAndTutorId(Long problemId, Long tutorId);

    int countByProblemIdAndStatusIn(Long problemId, List<ApplicationStatus> statuses);

    List<MatchingApplication> findByTutorIdAndStatusIn(Long tutorId, List<ApplicationStatus> statuses);

    List<MatchingApplication> findByStatusAndConfirmedAtBefore(ApplicationStatus status, LocalDateTime cutoff);
}
