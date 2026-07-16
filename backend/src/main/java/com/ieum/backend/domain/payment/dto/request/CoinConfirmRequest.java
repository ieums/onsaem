package com.ieum.backend.domain.payment.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class CoinConfirmRequest {

    @NotNull(message = "merchantId는 필수입니다")
    private String merchantId;

    @NotNull(message = "portonePaymentId는 필수입니다")
    private String portonePaymentId;

    private String method;  // optional, 기본 "CARD"
}