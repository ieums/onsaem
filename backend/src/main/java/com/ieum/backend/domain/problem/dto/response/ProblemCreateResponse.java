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
public class ProblemCreateResponse {

    private Long id;
    private String imageUrl;
    private String extractedText;
    private String summary;

    private Subject subject;
    private String subjectDisplayName;
    private String primaryType;
    private String secondaryType;

    private String grade;
    private Difficulty difficulty;
    private Integer totalDifficultyScore;
    private ExamType examType;

    private ProblemStatus status;
    private LocalDateTime createdAt;

    public static ProblemCreateResponse from(Problem problem) {
        return ProblemCreateResponse.builder()
                .id(problem.getId())
                .imageUrl(problem.getImageUrl())
                .extractedText(problem.getExtractedText())
                .summary(problem.getSummary())
                .subject(problem.getSubject())
                .subjectDisplayName(problem.getSubject().getDisplayName())
                .primaryType(problem.getPrimaryType())
                .secondaryType(problem.getSecondaryType())
                .grade(problem.getGrade())
                .difficulty(problem.getDifficulty())
                .totalDifficultyScore(problem.getTotalDifficultyScore())
                .examType(problem.getExamType())
                .status(problem.getStatus())
                .createdAt(problem.getCreatedAt())
                .build();
    }
}