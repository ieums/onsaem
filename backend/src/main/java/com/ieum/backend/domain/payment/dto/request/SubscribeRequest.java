package com.ieum.backend.domain.payment.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class SubscribeRequest {

    @NotNull(message = "학생 ID는 필수입니다")
    private Long studentId;

    @NotNull(message = "구독 플랜 ID는 필수입니다")
    private Long planId;

    private Boolean autoRenew;
}