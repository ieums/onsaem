package com.ieum.backend.domain.payment.dto.response;

import com.ieum.backend.domain.payment.entity.Payment;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class PaymentResponse {

    private Long id;
    private String merchantId;
    private Integer amount;
    private Integer coinAmount;
    private Integer bonusCoinAmount;
    private String productName;
    private String status;
    private String method;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;

    public static PaymentResponse from(Payment payment) {
        return PaymentResponse.builder()
                .id(payment.getId())
                .merchantId(payment.getMerchantId())
                .amount(payment.getAmount())
                .coinAmount(payment.getCoinAmount())
                .bonusCoinAmount(payment.getBonusCoinAmount())
                .productName(payment.getProductName())
                .status(payment.getStatus().name())
                .method(payment.getMethod() != null ? payment.getMethod().name() : null)
                .createdAt(payment.getCreatedAt())
                .completedAt(payment.getCompletedAt())
                .build();
    }
}