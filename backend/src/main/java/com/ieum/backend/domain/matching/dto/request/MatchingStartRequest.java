package com.ieum.backend.domain.matching.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class MatchingStartRequest {

    @NotNull(message = "탐색 시간은 필수입니다")
    @Min(value = 1, message = "탐색 시간은 1분 이상이어야 합니다")
    private Integer minutes;
}
