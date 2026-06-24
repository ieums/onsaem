package com.ieum.backend.domain.problem.dto.request;

import com.ieum.backend.domain.problem.entity.enums.Subject;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 여러 문제 감지 후 학생이 하나를 선택해 확정 등록하는 요청.
 * 1차 응답의 detectionId로 캐시된 OCR 결과를 꺼내 쓰므로 재OCR/재업로드가 없다.
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ProblemSelectRequest {

    @NotBlank(message = "detectionId는 필수입니다")
    private String detectionId;

    @NotNull(message = "선택한 문제 인덱스는 필수입니다")
    private Integer selectedIndex;

    @NotNull(message = "학생 ID는 필수입니다")
    private Long studentId;

    /** 학생이 고른 과목 (없으면 AI 판정값) */
    private Subject subject;

    @Size(max = 500, message = "설명은 500자 이내로 입력해주세요")
    private String studentDescription;
}
