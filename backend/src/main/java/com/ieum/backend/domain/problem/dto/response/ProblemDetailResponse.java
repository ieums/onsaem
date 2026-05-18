package com.ieum.backend.domain.problem.dto.response;

import com.ieum.backend.domain.problem.entity.*;
import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class ProblemDetailResponse {

    private Long id;
    private Long studentId;
    private String imageUrl;
    private String extractedText;
    private String summary;
    private String userDescription;

    private Subject subject;
    private String subjectDisplayName;
    private String primaryType;
    private String secondaryType;

    private String grade;
    private Difficulty difficulty;
    private String difficultyDisplayName;
    private Integer totalDifficultyScore;
    private ExamType examType;
    private String examTypeDisplayName;

    private ProblemStatus status;
    private String statusDisplayName;
    private LocalDateTime createdAt;
    private LocalDateTime resolvedAt;

    public static ProblemDetailResponse from(Problem problem) {
        return ProblemDetailResponse.builder()
                .id(problem.getId())
                .studentId(problem.getStudentId())
                .imageUrl(problem.getImageUrl())
                .extractedText(problem.getExtractedText())
                .summary(problem.getSummary())
                .userDescription(problem.getUserDescription())
                .subject(problem.getSubject())
                .subjectDisplayName(problem.getSubject().getDisplayName())
                .primaryType(problem.getPrimaryType())
                .secondaryType(problem.getSecondaryType())
                .grade(problem.getGrade())
                .difficulty(problem.getDifficulty())
                .difficultyDisplayName(
                        problem.getDifficulty() != null ? problem.getDifficulty().getDisplayName() : null
                )
                .totalDifficultyScore(problem.getTotalDifficultyScore())
                .examType(problem.getExamType())
                .examTypeDisplayName(
                        problem.getExamType() != null ? problem.getExamType().getDisplayName() : null
                )
                .status(problem.getStatus())
                .statusDisplayName(problem.getStatus().getDisplayName())
                .createdAt(problem.getCreatedAt())
                .resolvedAt(problem.getResolvedAt())
                .build();
    }
}