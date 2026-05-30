package com.ieum.backend.domain.payment.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class CalculateSettlementRequest {

    @NotNull(message = "강사 ID는 필수입니다")
    private Long tutorId;

    @NotNull(message = "강의 ID는 필수입니다")
    private Long lessonId;

    @NotNull(message = "총 코인은 필수입니다")
    @Positive(message = "총 코인은 0보다 커야 합니다")
    private Integer totalCoin;
}