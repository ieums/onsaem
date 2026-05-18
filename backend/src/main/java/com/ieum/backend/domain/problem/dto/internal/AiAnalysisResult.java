package com.ieum.backend.domain.problem.dto.internal;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AiAnalysisResult {

    @JsonProperty("extractedText")
    private String extractedText;

    @JsonProperty("summary")
    private String summary;

    @JsonProperty("subject")
    private Subject subject;

    @JsonProperty("primaryType")
    private String primaryType;

    @JsonProperty("secondaryType")
    private String secondaryType;

    @JsonProperty("grade")
    private String grade;

    @JsonProperty("difficulty")
    private Difficulty difficulty;

    @JsonProperty("totalDifficultyScore")
    private Integer totalDifficultyScore;

    @JsonProperty("examType")
    private ExamType examType;
}