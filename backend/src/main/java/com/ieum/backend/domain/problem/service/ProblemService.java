package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.matching.repository.MatchingApplicationRepository;
import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;
import com.ieum.backend.domain.problem.dto.request.ClassificationUpdateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.dto.response.ProblemDetailResponse;
import com.ieum.backend.domain.problem.dto.response.SearchingProblemResponse;
import com.ieum.backend.domain.problem.dto.response.StudentProblemResponse;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
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
    private final MatchingApplicationRepository matchingApplicationRepository;
    private final ImageStorageService imageStorageService;
    private final GeminiClient geminiClient;

    /**
     * 문제 등록 (이미지 1~N장)
     */
    @Transactional
    public ProblemCreateResponse createProblem(List<MultipartFile> images,
                                               ProblemCreateRequest request) {
        // 1. 이미지들 저장
        List<String> imageUrls = imageStorageService.storeAll(images);

        // 2. AI 분석 (Gemini가 detectedProblems 배열 반환)
        AiAnalysisResult aiResult = geminiClient.analyze(images);
        List<AiAnalysisResult.DetectedProblem> detected = aiResult.getDetectedProblems();

        if (detected == null || detected.isEmpty()) {
            throw new RuntimeException("이미지에서 문제를 감지하지 못했습니다.");
        }

        // 3. 분기 처리
        Integer selectedIndex = request.getSelectedProblemIndex();

        // (a) 1개만 감지 → 자동 등록
        if (detected.size() == 1) {
            Problem problem = saveProblem(detected.get(0), imageUrls, request);
            return ProblemCreateResponse.from(problem);
        }

        // (b) 여러 개 감지 + 학생이 선택함 → 선택한 것만 등록
        if (selectedIndex != null) {
            if (selectedIndex < 0 || selectedIndex >= detected.size()) {
                throw new RuntimeException("올바르지 않은 문제 인덱스입니다: " + selectedIndex);
            }
            Problem problem = saveProblem(detected.get(selectedIndex), imageUrls, request);
            return ProblemCreateResponse.from(problem);
        }

        // (c) 여러 개 감지 + 학생 선택 안 함 → 선택 요청
        return ProblemCreateResponse.fromDetection(detected, imageUrls);
    }

    /**
     * Problem 저장 (공통 로직)
     */
    private Problem saveProblem(AiAnalysisResult.DetectedProblem dp, List<String> imageUrls,
                                ProblemCreateRequest request) {
        Problem problem = Problem.builder()
                .studentId(request.getStudentId())
                .imageUrls(imageUrls)
                .extractedText(dp.getExtractedText())
                .summary(dp.getSummary())
                .subject(dp.getSubject())
                .primaryType(dp.getPrimaryType())
                .secondaryType(dp.getSecondaryType())
                .difficulty(dp.getDifficulty())
                .totalDifficultyScore(dp.getTotalDifficultyScore())
                .examType(dp.getExamType())
                .studentDescription(request.getStudentDescription())
                .build();

        return problemRepository.save(problem);
    }

    /**
     * 문제 단건 조회
     */
    public ProblemDetailResponse getProblem(Long id) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("문제를 찾을 수 없습니다: " + id));
        return ProblemDetailResponse.from(problem);
    }

    /**
     * 분류 수정 (학생이 AI 분류 결과 수정)
     */
    @Transactional
    public ProblemDetailResponse updateClassification(Long id, ClassificationUpdateRequest request) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("문제를 찾을 수 없습니다. id=" + id));

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
        List<Problem> problems = problemRepository.findAllSearching(LocalDateTime.now());
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
        return problemRepository.findAllByStudentId(studentId).stream()
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
                .orElseThrow(() -> new RuntimeException("문제를 찾을 수 없습니다. id=" + id));
        problem.cancel();
    }
}