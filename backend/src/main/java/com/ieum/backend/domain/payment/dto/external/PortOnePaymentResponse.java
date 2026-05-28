package com.ieum.backend.domain.payment.dto.external;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record PortOnePaymentResponse(
        String id,           // paymentId
        String status,       // "READY" | "PAID" | "FAILED" | "CANCELLED" | ...
        Amount amount,
        String orderName
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Amount(
            long total,      // 총 결제 금액
            long taxFree,
            long vat
    ) {}
}