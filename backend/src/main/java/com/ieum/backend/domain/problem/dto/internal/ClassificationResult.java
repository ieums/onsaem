package com.ieum.backend.domain.problem.dto.internal;

import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 2단계 분류 결과 — 텍스트를 분석해서 나온 분류
 */
@Getter
@Setter
@NoArgsConstructor
public class ClassificationResult {
    private String summary;
    private Subject subject;
    private String primaryType;
    private String secondaryType;
    private Difficulty difficulty;
    private Integer totalDifficultyScore;
    private ExamType examType;
}