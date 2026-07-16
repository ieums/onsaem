package com.ieum.backend.domain.problem.dto.request;

import com.ieum.backend.domain.problem.entity.enums.Subject;
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

    /** 학생이 고른 과목. 지정되면 AI 판정보다 우선해 과목을 확정한다(없으면 AI 판정 사용). */
    private Subject subject;

    @Size(max = 500, message = "설명은 500자 이내로 입력해주세요")
    private String studentDescription;

    /**
     * 한 사진에 문제가 여러 개 감지됐을 때, 학생이 선택한 문제의 인덱스 (0부터)
     * null이면 → 1개만 감지된 경우 자동 등록
     *           여러 개 감지되면 needsSelection 응답 후 학생 선택 받기
     */
    private Integer selectedProblemIndex;
}