package com.ieum.backend.domain.problem.dto.response;

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

@Getter
@Builder
@AllArgsConstructor
public class ProblemDetailResponse {

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
    private LocalDateTime resolvedAt;
    /** (2) 여러 장 한 문제 → 페이지 순서 재정렬 가능 여부. */
    private boolean multiPage;

    public static ProblemDetailResponse from(Problem problem) {
        return ProblemDetailResponse.builder()
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
                .resolvedAt(problem.getResolvedAt())
                .multiPage(problem.isMultiPage())
                .build();
    }
}