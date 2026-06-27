package com.ieum.backend.domain.problem.dto.request;

import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * (2) 여러 장 한 문제의 페이지 순서 재정렬 요청.
 * order는 현재 인덱스의 순열(예: [2,0,1] → 현재 2번째 장을 맨 앞으로).
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class PageOrderUpdateRequest {

    @NotEmpty(message = "순서 정보는 필수입니다")
    private List<Integer> order;
}
