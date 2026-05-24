package com.ieum.backend.domain.problem.dto.internal;

import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class AiAnalysisResult {

    private List<DetectedProblem> detectedProblems = new ArrayList<>();

    /**
     * 이미지에서 감지된 개별 문제 1건
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class DetectedProblem {
        private String extractedText;
        private String summary;
        private Subject subject;
        private String primaryType;
        private String secondaryType;
        private Difficulty difficulty;
        private Integer totalDifficultyScore;
        private ExamType examType;
    }
}