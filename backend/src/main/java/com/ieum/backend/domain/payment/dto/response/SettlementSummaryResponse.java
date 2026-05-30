package com.ieum.backend.domain.payment.dto.response;

public record SettlementSummaryResponse(
        Long tutorId,
        Integer totalAmount,       // 누적 총 정산 금액
        Integer transferredAmount, // 송금 완료된 총 금액
        Integer pendingAmount,     // 송금 대기 + 계산 완료 금액
        Integer settlementCount    // 정산 건수
) {}