package com.ieum.backend.domain.matching.service;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.service.LessonService;
import com.ieum.backend.domain.matching.dto.response.ApplicantResponse;
import com.ieum.backend.domain.matching.dto.response.TutorApplicationResponse;
import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import com.ieum.backend.domain.matching.repository.MatchingApplicationRepository;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MatchingService {

    private final ProblemRepository problemRepository;
    private final MatchingApplicationRepository applicationRepository;
    private final MatchingNotificationService notificationService;
    private final LessonService lessonService;

    @Transactional
    public void startSearching(Long problemId, int minutes) {
        Problem problem = problemRepository.findById(problemId)
                .orElseThrow(() -> new IllegalStateException("문제를 찾을 수 없습니다. id=" + problemId));

        if (problem.getStatus() != ProblemStatus.PENDING) {
            throw new IllegalStateException("탐색을 시작할 수 없는 상태입니다. status=" + problem.getStatus());
        }

        problem.startSearching(LocalDateTime.now().plusMinutes(minutes));
    }

    @Transactional
    public void applyToLesson(Long problemId, Long tutorId) {
        Problem problem = problemRepository.findById(problemId)
                .orElseThrow(() -> new IllegalStateException("문제를 찾을 수 없습니다. id=" + problemId));

        if (!problem.isSearching()) {
            throw new IllegalStateException("현재 강사를 탐색 중인 문제가 아닙니다. id=" + problemId);
        }

        boolean inLesson = !applicationRepository.findByTutorIdAndStatus(tutorId, ApplicationStatus.UNAVAILABLE).isEmpty();
        if (inLesson) {
            throw new IllegalStateException("강사가 현재 수업 중입니다. tutorId=" + tutorId);
        }

        if (applicationRepository.existsByProblemIdAndTutorId(problemId, tutorId)) {
            throw new IllegalStateException("이미 신청한 문제입니다. problemId=" + problemId + ", tutorId=" + tutorId);
        }

        MatchingApplication application = MatchingApplication.builder()
                .problemId(problemId)
                .tutorId(tutorId)
                .build();
        applicationRepository.save(application);

        notificationService.notifyTutorApplied(problemId, tutorId, problem.getStudentId());
    }

    public List<ApplicantResponse> getApplicants(Long problemId) {
        List<ApplicationStatus> visibleStatuses = List.of(
                ApplicationStatus.PENDING,
                ApplicationStatus.UNAVAILABLE,
                ApplicationStatus.ACCEPTED
        );
        return applicationRepository.findByProblemIdAndStatusIn(problemId, visibleStatuses)
                .stream()
                .map(ApplicantResponse::from)
                .toList();
    }

    @Transactional
    public void acceptTutor(Long problemId, Long tutorId) {
        Problem problem = problemRepository.findById(problemId)
                .orElseThrow(() -> new IllegalStateException("문제를 찾을 수 없습니다. id=" + problemId));

        MatchingApplication application = applicationRepository.findByProblemIdAndTutorId(problemId, tutorId)
                .filter(a -> a.getStatus() == ApplicationStatus.PENDING)
                .orElseThrow(() -> new IllegalStateException("해당 강사의 PENDING 신청을 찾을 수 없습니다. tutorId=" + tutorId));

        application.confirm();

        notificationService.notifyMatchRequested(problemId, tutorId, problem.getStudentId());
    }

    @Transactional
    public void confirmMatch(Long problemId, Long tutorId, String confirmedBy) {
        MatchingApplication application = applicationRepository.findByProblemIdAndTutorId(problemId, tutorId)
                .filter(a -> a.getStatus() == ApplicationStatus.CONFIRMING)
                .orElseThrow(() -> new IllegalStateException("CONFIRMING 상태의 신청을 찾을 수 없습니다."));

        if ("tutor".equals(confirmedBy)) {
            application.tutorConfirm();
        } else {
            application.studentConfirm();
        }

        if (application.isTutorConfirmed() && application.isStudentConfirmed()) {
            application.accept();

            Problem problem = problemRepository.findById(problemId)
                    .orElseThrow(() -> new IllegalStateException("문제를 찾을 수 없습니다. id=" + problemId));
            Long studentId = problem.getStudentId();
            problem.matchTutor();

            applicationRepository.findByProblemIdAndStatusIn(problemId, List.of(ApplicationStatus.PENDING))
                    .forEach(app -> {
                        app.reject();
                        notificationService.notifyProblemMatched(problemId, app.getTutorId());
                    });

            String channelName = "problem-" + problemId;
            Lesson lesson = lessonService.createLesson(tutorId, studentId, channelName);
            notificationService.notifyMatched(problemId, tutorId, studentId, lesson.getId(), channelName, problem.getImageUrls());
        }
    }

    @Transactional
    public void cancelMatch(Long problemId, Long tutorId, String cancelledBy) {
        Problem problem = problemRepository.findById(problemId)
                .orElseThrow(() -> new IllegalStateException("문제를 찾을 수 없습니다. id=" + problemId));
        Long studentId = problem.getStudentId();

        applicationRepository.findByProblemIdAndTutorId(problemId, tutorId)
                .filter(a -> a.getStatus() == ApplicationStatus.CONFIRMING)
                .ifPresent(app -> {
                    app.reject();
                    notificationService.notifyMatchCancelled(problemId, tutorId, studentId, cancelledBy);
                });
    }

    @Transactional
    public void tutorStartLesson(Long tutorId) {
        List<MatchingApplication> pendingApplications =
                applicationRepository.findByTutorIdAndStatus(tutorId, ApplicationStatus.PENDING);

        pendingApplications.forEach(application -> {
            application.markUnavailable();
            notificationService.notifyTutorUnavailable(application.getProblemId(), tutorId);
        });
    }

    @Transactional
    public void tutorEndLesson(Long tutorId) {
        List<MatchingApplication> unavailableApplications =
                applicationRepository.findByTutorIdAndStatus(tutorId, ApplicationStatus.UNAVAILABLE);

        unavailableApplications.forEach(application -> {
            application.restorePending();
            notificationService.notifyTutorAvailable(application.getProblemId(), tutorId);
        });
    }

    @Transactional
    public void expireSearch(Long problemId) {
        Problem problem = problemRepository.findById(problemId)
                .orElseThrow(() -> new IllegalStateException("문제를 찾을 수 없습니다. id=" + problemId));

        problem.stopSearching();
        notificationService.notifySearchExpired(problem.getStudentId(), problemId);
    }

    @Transactional
    public void cancelApplication(Long problemId, Long tutorId) {
        MatchingApplication application = applicationRepository
                .findByProblemIdAndTutorId(problemId, tutorId)
                .orElseThrow(() -> new IllegalStateException(
                        "신청 내역을 찾을 수 없습니다. problemId=" + problemId + ", tutorId=" + tutorId));

        if (application.getStatus() != ApplicationStatus.PENDING) {
            throw new IllegalStateException(
                    "PENDING 상태인 신청만 취소할 수 있습니다. status=" + application.getStatus());
        }

        applicationRepository.delete(application);
    }

    @Transactional
    public void extendSearch(Long problemId, int minutes) {
        Problem problem = problemRepository.findById(problemId)
                .orElseThrow(() -> new IllegalStateException("문제를 찾을 수 없습니다. id=" + problemId));

        problem.extendDeadline(LocalDateTime.now().plusMinutes(minutes));
    }

    @Transactional
    public void rejectProblem(Long problemId, Long tutorId) {
        boolean alreadyRejected = applicationRepository
                .findByProblemIdAndTutorId(problemId, tutorId)
                .map(a -> a.getStatus() == ApplicationStatus.REJECTED)
                .orElse(false);
        if (alreadyRejected) return;

        MatchingApplication application = MatchingApplication.builder()
                .problemId(problemId)
                .tutorId(tutorId)
                .build();
        application.reject();
        applicationRepository.save(application);
    }

    public List<TutorApplicationResponse> getTutorApplications(Long tutorId) {
        List<ApplicationStatus> statuses = List.of(
                ApplicationStatus.PENDING,
                ApplicationStatus.CONFIRMING,
                ApplicationStatus.UNAVAILABLE,
                ApplicationStatus.ACCEPTED
        );

        List<MatchingApplication> applications =
                applicationRepository.findByTutorIdAndStatusIn(tutorId, statuses);

        List<Long> problemIds = applications.stream()
                .map(MatchingApplication::getProblemId)
                .distinct()
                .toList();

        Map<Long, Problem> problemMap = problemRepository.findAllByIdIn(problemIds).stream()
                .collect(Collectors.toMap(Problem::getId, p -> p));

        return applications.stream()
                .filter(app -> problemMap.containsKey(app.getProblemId()))
                .map(app -> TutorApplicationResponse.from(app, problemMap.get(app.getProblemId())))
                .toList();
    }
}
