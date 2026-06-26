package com.ieum.backend.domain.problem.dto.response;

import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class SearchingProblemResponse {

    private Long problemId;
    private Long studentId;
    private String summary;
    private String studentDescription;   // 학생이 직접 입력한 설명
    private Subject subject;
    private String primaryType;
    private String secondaryType;
    private Difficulty difficulty;
    private ExamType examType;
    private List<String> imageUrls;
    private LocalDateTime searchDeadline;
    private LocalDateTime createdAt;
    private boolean alreadyApplied;

    public static SearchingProblemResponse from(Problem problem, boolean alreadyApplied) {
        return SearchingProblemResponse.builder()
                .problemId(problem.getId())
                .studentId(problem.getStudentId())
                .summary(problem.getSummary())
                .studentDescription(problem.getStudentDescription())
                .subject(problem.getSubject())
                .primaryType(problem.getPrimaryType())
                .secondaryType(problem.getSecondaryType())
                .difficulty(problem.getDifficulty())
                .examType(problem.getExamType())
                .imageUrls(problem.getImageUrls())
                .searchDeadline(problem.getSearchDeadline())
                .createdAt(problem.getCreatedAt())
                .alreadyApplied(alreadyApplied)
                .build();
    }
}
