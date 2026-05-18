package com.ieum.backend.domain.problem.dto.request;


import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ClassificationUpdateRequest {

    @NotNull(message = "과목은 필수입니다")
    private Subject subject;

    private String primaryType;
    private String secondaryType;
    private Difficulty difficulty;
    private ExamType examType;
}