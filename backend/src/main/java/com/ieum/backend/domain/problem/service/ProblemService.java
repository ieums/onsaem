package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.repository.MatchingApplicationRepository;
import com.ieum.backend.domain.matching.service.MatchingNotificationService;
import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;
import com.ieum.backend.domain.problem.dto.request.ClassificationUpdateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemSelectRequest;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.dto.response.ProblemDetailResponse;
import com.ieum.backend.domain.problem.dto.response.SearchingProblemResponse;
import com.ieum.backend.domain.problem.dto.response.StudentProblemResponse;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProblemService {

    private final ProblemRepository problemRepository;
    private final TutorRepository tutorRepository;
    private final MatchingApplicationRepository matchingApplicationRepository;
    private final MatchingNotificationService notificationService;
    private final ImageStorageService imageStorageService;
    private final GeminiClient geminiClient;
    private final DetectionCache detectionCache;

    /** 학생 1명이 동시에 등록(탐색 중)할 수 있는 질문 수 상한. */
    private static final int MAX_ACTIVE_PROBLEMS = 3;

    /**
     * 문제 등록 (이미지 1~N장)
     *
     * 이미지 저장 + 수 초 걸리는 Gemini 호출은 DB 트랜잭션 밖에서 수행한다(NOT_SUPPORTED).
     * 트랜잭션은 실제 INSERT 시점(saveProblem → repository.save)에만 짧게 열려,
     * 외부 호출이 DB 커넥션을 오래 점유하지 않는다.
     *
     * TODO: AI 분석이 실패하면 이미 저장된 이미지가 고아로 남는다.
     *       ImageStorageService에 delete를 추가해 실패 시 정리 필요(별도 작업).
     */
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public ProblemCreateResponse createProblem(List<MultipartFile> images,
                                               ProblemCreateRequest request) {
        // 0. 동시 등록 개수 제한 — OCR/이미지 저장 전에 먼저 막아 불필요한 비용을 줄인다.
        assertUnderActiveLimit(request.getStudentId());

        // 1. 이미지들 저장 (트랜잭션 밖)
        List<String> imageUrls = imageStorageService.storeAll(images);

        // 2~3. AI 분석 + 분기 처리. 실패하면 방금 저장한 이미지를 정리(고아 방지)
        try {
            AiAnalysisResult aiResult = geminiClient.analyze(images);
            List<AiAnalysisResult.DetectedProblem> detected = aiResult.getDetectedProblems();

            if (detected == null || detected.isEmpty()) {
                throw BusinessException.badRequest("이미지에서 문제를 감지하지 못했습니다.");
            }

            Integer selectedIndex = request.getSelectedProblemIndex();

            // (a) 1개만 감지 → 자동 등록
            if (detected.size() == 1) {
                Problem problem = saveProblem(detected.get(0), imageUrls,
                        request.getStudentId(), request.getSubject(), request.getStudentDescription());
                return ProblemCreateResponse.from(problem, detected.get(0).isClassificationFailed());
            }

            // (b) 여러 개 감지 + 학생이 선택함(레거시 경로) → 선택한 것만 등록
            if (selectedIndex != null) {
                if (selectedIndex < 0 || selectedIndex >= detected.size()) {
                    throw BusinessException.badRequest("올바르지 않은 문제 인덱스입니다: " + selectedIndex);
                }
                Problem problem = saveProblem(detected.get(selectedIndex), imageUrls,
                        request.getStudentId(), request.getSubject(), request.getStudentDescription());
                return ProblemCreateResponse.from(problem, detected.get(selectedIndex).isClassificationFailed());
            }

            // (c) 여러 개 감지 + 선택 안 함 → 결과를 캐시하고 detectionId 반환.
            //     선택은 /problems/select가 캐시에서 꺼내 저장(재OCR·재업로드 없음).
            String detectionId = detectionCache.put(detected, imageUrls);
            return ProblemCreateResponse.fromDetection(detected, imageUrls, detectionId);

        } catch (RuntimeException e) {
            // 단, 선택 대기(캐시에 올린 경우)는 이미지가 살아있어야 하므로 정리하지 않는다.
            imageStorageService.deleteAll(imageUrls);
            throw e;
        }
    }

    /**
     * 여러 문제 감지 후 학생이 하나를 선택해 확정 등록.
     * 1차 OCR 결과를 캐시에서 꺼내 쓰므로 재OCR/재업로드가 없다.
     */
    @Transactional
    public ProblemCreateResponse selectDetectedProblem(ProblemSelectRequest request) {
        DetectionCache.Entry entry = detectionCache.get(request.getDetectionId());
        if (entry == null) {
            throw BusinessException.badRequest("문제 선택 시간이 만료됐어요. 다시 업로드해 주세요.");
        }
        int idx = request.getSelectedIndex();
        if (idx < 0 || idx >= entry.detected().size()) {
            throw BusinessException.badRequest("올바르지 않은 문제 인덱스입니다: " + idx);
        }

        Problem problem = saveProblem(entry.detected().get(idx), entry.imageUrls(),
                request.getStudentId(), request.getSubject(), request.getStudentDescription());
        detectionCache.remove(request.getDetectionId());
        return ProblemCreateResponse.from(problem, entry.detected().get(idx).isClassificationFailed());
    }

    /**
     * Problem 저장 (공통 로직). 과목은 학생 선택값 우선(없으면 AI 판정).
     */
    private Problem saveProblem(AiAnalysisResult.DetectedProblem dp, List<String> imageUrls,
                                Long studentId, Subject chosenSubject, String studentDescription) {
        // 실제 등록 직전 재확인(선택 경로 포함, 동시 등록 경합 방어).
        assertUnderActiveLimit(studentId);

        Subject subject = chosenSubject != null ? chosenSubject : dp.getSubject();
        Problem problem = Problem.builder()
                .studentId(studentId)
                .imageUrls(imageUrls)
                .extractedText(dp.getExtractedText())
                .summary(dp.getSummary())
                .subject(subject)
                .primaryType(dp.getPrimaryType())
                .secondaryType(dp.getSecondaryType())
                .difficulty(dp.getDifficulty())
                .totalDifficultyScore(dp.getTotalDifficultyScore())
                .examType(dp.getExamType())
                .studentDescription(studentDescription)
                .build();

        return problemRepository.save(problem);
    }

    /** 탐색 중(매칭 대기) 질문이 상한 이상이면 등록을 막는다. */
    private void assertUnderActiveLimit(Long studentId) {
        long active = problemRepository.countByStudentIdAndStatus(studentId, ProblemStatus.PENDING);
        if (active >= MAX_ACTIVE_PROBLEMS) {
            throw BusinessException.conflict(
                    "동시에 등록할 수 있는 질문은 최대 " + MAX_ACTIVE_PROBLEMS
                            + "개예요. 기존 질문을 마치거나 취소한 뒤 다시 시도해 주세요.");
        }
    }

    /**
     * 문제 단건 조회
     */
    public ProblemDetailResponse getProblem(Long id) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다: " + id));
        return ProblemDetailResponse.from(problem);
    }

    /**
     * 분류 수정 (학생이 AI 분류 결과 수정)
     */
    @Transactional
    public ProblemDetailResponse updateClassification(Long id, ClassificationUpdateRequest request) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다. id=" + id));

        problem.updateClassification(
                request.getSubject(),
                request.getPrimaryType(),
                request.getSecondaryType(),
                request.getDifficulty(),
                request.getExamType()
        );

        return ProblemDetailResponse.from(problem);
    }

    /**
     * 강사 탐색 중인 문제 목록 조회
     */
    public List<SearchingProblemResponse> getSearchingProblems(Long tutorId) {
        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));

        List<Subject> subjects = tutor.getSubjects().stream()
                .map(s -> { try { return Subject.valueOf(s); } catch (IllegalArgumentException ignored) { return null; } })
                .filter(s -> s != null && s != Subject.UNKNOWN)
                .toList();

        if (subjects.isEmpty()) {
            return List.of();
        }

        List<Problem> problems = problemRepository.findAllSearchingBySubjects(LocalDateTime.now(), subjects);
        return problems.stream()
                .map(p -> SearchingProblemResponse.from(p,
                        matchingApplicationRepository.existsByProblemIdAndTutorId(p.getId(), tutorId)))
                .toList();
    }

    /**
     * 학생 문제 목록 조회
     */
    public List<StudentProblemResponse> getStudentProblems(Long studentId) {
        List<ApplicationStatus> countStatuses = List.of(ApplicationStatus.PENDING, ApplicationStatus.UNAVAILABLE);
        return problemRepository.findAllByStudentIdAndStatus(studentId, ProblemStatus.PENDING).stream()
                .map(problem -> {
                    int count = matchingApplicationRepository.countByProblemIdAndStatusIn(problem.getId(), countStatuses);
                    return StudentProblemResponse.from(problem, count);
                })
                .toList();
    }

    /**
     * 문제 취소
     */
    @Transactional
    public void cancelProblem(Long id) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다. id=" + id));

        matchingApplicationRepository
                .findByProblemIdAndStatusIn(id, List.of(ApplicationStatus.PENDING))
                .forEach(app -> {
                    app.cancel();
                    notificationService.notifyProblemCancelled(id, app.getTutorId());
                });

        problem.cancel();
    }
}