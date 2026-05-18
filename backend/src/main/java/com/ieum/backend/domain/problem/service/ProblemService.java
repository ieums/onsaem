package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;
import com.ieum.backend.domain.problem.dto.request.ClassificationUpdateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.dto.response.ProblemDetailResponse;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProblemService {

    private final ProblemRepository problemRepository;
    private final ImageStorageService imageStorageService;
    private final GeminiClient geminiClient;

    /**
     * 문제 등록 (핵심 API)
     * 이미지 저장 → AI 분석 → DB 저장
     */
    @Transactional
    public ProblemCreateResponse createProblem(MultipartFile image, ProblemCreateRequest request) {

        String imageUrl = imageStorageService.store(image);

        AiAnalysisResult aiResult = geminiClient.analyze(image); //현재 api key 연결이 되어있지 않아 목업데이터 출력

        Problem problem = Problem.builder()
                .studentId(request.getStudentId())
                .imageUrl(imageUrl)
                .extractedText(aiResult.getExtractedText())
                .summary(aiResult.getSummary())
                .subject(aiResult.getSubject())
                .primaryType(aiResult.getPrimaryType())
                .secondaryType(aiResult.getSecondaryType())
                .grade(aiResult.getGrade())
                .difficulty(aiResult.getDifficulty())
                .totalDifficultyScore(aiResult.getTotalDifficultyScore())
                .examType(request.getExamType() != null
                        ? request.getExamType()           // 학생이 직접 선택했으면 우선
                        : aiResult.getExamType())         // 아니면 AI 추측
                .userDescription(request.getUserDescription())
                .build();

        problemRepository.save(problem);

        // 5. 응답
        return ProblemCreateResponse.from(problem);
    }

    /**
     * 문제 상세 조회
     */
    public ProblemDetailResponse getProblem(Long id) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("문제를 찾을 수 없습니다. id=" + id));
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
     * 문제 취소
     */
    @Transactional
    public void cancelProblem(Long id) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("문제를 찾을 수 없습니다. id=" + id));
        problem.cancel();
    }
}