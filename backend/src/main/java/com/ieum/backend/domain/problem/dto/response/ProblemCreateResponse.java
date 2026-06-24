package com.ieum.backend.domain.problem.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult.DetectedProblem;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL) //재답변할 때 null인 경우 보여주지 않음
@Getter
@Builder
@AllArgsConstructor
public class ProblemCreateResponse {

    // ─── 여러 문제 감지 시 (학생 선택 필요) ───
    private Boolean needsSelection;
    private String detectionId;            // 선택 시 /problems/select에 그대로 전달 (재OCR 방지)
    private List<DetectedProblem> allDetected;

    // ─── 등록 완료 시 (단일 문제) ───
    private Long id;
    private Long studentId;
    private List<String> imageUrls;
    private String extractedText;
    private String summary;
    private Subject subject;
    private String primaryType;
    private String secondaryType;
    private Difficulty difficulty;
    private Integer totalDifficultyScore;
    private ExamType examType;
    private ProblemStatus status;
    private String studentDescription;
    private LocalDateTime createdAt;

    /** 분류 API 실패로 기본값 등록됨 → 프론트가 분류 수정 화면으로 유도. */
    private Boolean needsClassification;

    /**
     * 등록 완료된 Problem → 응답 변환
     */
    public static ProblemCreateResponse from(Problem problem) {
        return from(problem, false);
    }

    public static ProblemCreateResponse from(Problem problem, boolean needsClassification) {
        return ProblemCreateResponse.builder()
                .needsSelection(false)
                .needsClassification(needsClassification)
                .id(problem.getId())
                .studentId(problem.getStudentId())
                .imageUrls(problem.getImageUrls())
                .extractedText(problem.getExtractedText())
                .summary(problem.getSummary())
                .subject(problem.getSubject())
                .primaryType(problem.getPrimaryType())
                .secondaryType(problem.getSecondaryType())
                .difficulty(problem.getDifficulty())
                .totalDifficultyScore(problem.getTotalDifficultyScore())
                .examType(problem.getExamType())
                .status(problem.getStatus())
                .studentDescription(problem.getStudentDescription())
                .createdAt(problem.getCreatedAt())
                .build();
    }

    /**
     * 여러 문제 감지 → 학생 선택 유도 응답
     */
    public static ProblemCreateResponse fromDetection(List<DetectedProblem> detected,
                                                      List<String> imageUrls,
                                                      String detectionId) {
        return ProblemCreateResponse.builder()
                .needsSelection(true)
                .detectionId(detectionId)
                .allDetected(detected)
                .imageUrls(imageUrls)
                .build();
    }
}