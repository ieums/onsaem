package com.ieum.backend.domain.matching.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class MatchingApplyRequest {

    @NotNull(message = "강사 ID는 필수입니다")
    private Long tutorId;
}
