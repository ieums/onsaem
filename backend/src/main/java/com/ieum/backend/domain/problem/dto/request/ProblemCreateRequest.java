package com.ieum.backend.domain.problem.dto.request;

import com.ieum.backend.domain.problem.entity.enums.ExamType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ProblemCreateRequest {

    @NotNull(message = "학생 ID는 필수입니다")
    private Long studentId;

    @Size(max = 500, message = "설명은 500자 이내로 입력해주세요")
    private String studentDescription;

    private ExamType examType;
}