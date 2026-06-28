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
public class StudentProblemResponse {

    private Long problemId;
    private String summary;
    private Subject subject;
    private String primaryType;
    private String secondaryType;
    private Difficulty difficulty;
    private ExamType examType;
    private ProblemStatus status;
    private boolean searching;
    private LocalDateTime searchDeadline;
    private LocalDateTime createdAt;
    private List<String> imageUrls;
    private int applicantCount;
    /** (2) 여러 장 한 문제로 등록돼 페이지 순서 재정렬이 가능한지. */
    private boolean multiPage;

    public static StudentProblemResponse from(Problem problem, int applicantCount) {
        return StudentProblemResponse.builder()
                .problemId(problem.getId())
                .summary(problem.getSummary())
                .subject(problem.getSubject())
                .primaryType(problem.getPrimaryType())
                .secondaryType(problem.getSecondaryType())
                .difficulty(problem.getDifficulty())
                .examType(problem.getExamType())
                .status(problem.getStatus())
                .searching(problem.isSearching())
                .searchDeadline(problem.getSearchDeadline())
                .createdAt(problem.getCreatedAt())
                .imageUrls(problem.getImageUrls())
                .applicantCount(applicantCount)
                .multiPage(problem.isMultiPage())
                .build();
    }
}
