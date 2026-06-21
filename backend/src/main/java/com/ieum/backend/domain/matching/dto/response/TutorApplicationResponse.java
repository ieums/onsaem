package com.ieum.backend.domain.matching.dto.response;

import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
@AllArgsConstructor
public class TutorApplicationResponse {

    private Long applicationId;
    private Long problemId;
    private ApplicationStatus status;
    private LocalDateTime appliedAt;
    private String summary;
    private Subject subject;
    private String primaryType;
    private String secondaryType;
    private Difficulty difficulty;
    private ExamType examType;
    private List<String> imageUrls;
    private LocalDateTime searchDeadline;
    private LocalDateTime createdAt;
    private boolean searching;

    public static TutorApplicationResponse from(MatchingApplication application, Problem problem) {
        return TutorApplicationResponse.builder()
                .applicationId(application.getId())
                .problemId(application.getProblemId())
                .status(application.getStatus())
                .appliedAt(application.getAppliedAt())
                .summary(problem.getSummary())
                .subject(problem.getSubject())
                .primaryType(problem.getPrimaryType())
                .secondaryType(problem.getSecondaryType())
                .difficulty(problem.getDifficulty())
                .examType(problem.getExamType())
                .imageUrls(problem.getImageUrls())
                .searchDeadline(problem.getSearchDeadline())
                .createdAt(problem.getCreatedAt())
                .searching(problem.isSearching())
                .build();
    }
}
