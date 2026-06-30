package com.ieum.backend.domain.matching.scheduler;

import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import com.ieum.backend.domain.matching.repository.MatchingApplicationRepository;
import com.ieum.backend.domain.matching.service.MatchingNotificationService;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;


import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
public class MatchingScheduler {

    private final ProblemRepository problemRepository;
    private final MatchingApplicationRepository applicationRepository;
    private final MatchingNotificationService notificationService;

    @Scheduled(fixedDelay = 30000)
    @Transactional
    public void run() {
        checkExpiringSoon();
        checkExpired();
        checkConfirmingTimeout();
    }

    /** 1단계: 만료 1시간 전 알림 (탐색 기본 기간이 1일이므로 1시간 전 안내) */
    private void checkExpiringSoon() {
        LocalDateTime now = LocalDateTime.now();
        List<Problem> problems = problemRepository.findAllExpiringSoon(now, now.plusMinutes(60));
        for (Problem problem : problems) {
            notificationService.notifySearchExpiringSoon(problem.getStudentId(), problem.getId());
            problem.markExpiringSoonNotified();
        }
    }

    /** 2단계: 완전 만료 처리 */
    private void checkExpired() {
        LocalDateTime now = LocalDateTime.now();
        List<Problem> problems = problemRepository.findAllExpired(now);
        for (Problem problem : problems) {
            problem.markExpired();
            applicationRepository
                    .findByProblemIdAndStatusIn(problem.getId(), List.of(ApplicationStatus.PENDING))
                    .forEach(app -> app.expire());
            notificationService.notifySearchExpired(problem.getStudentId(), problem.getId());
        }
    }

    /** 3단계: CONFIRMING 5분 타임아웃 처리 */
    private void checkConfirmingTimeout() {
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(5);
        List<MatchingApplication> timedOut = applicationRepository
                .findByStatusAndConfirmedAtBefore(ApplicationStatus.CONFIRMING, cutoff);

        for (MatchingApplication app : timedOut) {
            Problem problem = problemRepository.findById(app.getProblemId()).orElse(null);
            if (problem == null) continue;

            String cancelledBy = !app.isTutorConfirmed() ? "timeout_tutor" : "timeout_student";

            app.restorePending();
            app.resetConfirmation();
            notificationService.notifyMatchCancelled(
                    app.getProblemId(), app.getTutorId(), problem.getStudentId(), cancelledBy
            );
        }
    }
}
