package com.ieum.backend.domain.problem.dto.request;

import com.ieum.backend.domain.problem.entity.enums.Subject;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 문제 등록 요청(multipart의 data 파트).
 * 등록하는 학생은 요청값이 아니라 JWT 인증 주체에서 정한다.
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ProblemCreateRequest {

    /** 학생이 고른 과목. 지정되면 AI 판정보다 우선해 과목을 확정한다(없으면 AI 판정 사용). */
    private Subject subject;

    @Size(max = 500, message = "설명은 500자 이내로 입력해주세요")
    private String studentDescription;
}