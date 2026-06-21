package com.ieum.backend.domain.payment.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionConfirmRequest {

    @NotNull(message = "merchantId는 필수입니다")
    private String merchantId;

    @NotNull(message = "portonePaymentId는 필수입니다")
    private String portonePaymentId;

    @NotNull(message = "결제 수단은 필수입니다")
    private String method;

    // 선택 — 기본값 false
    private Boolean autoRenew;
}