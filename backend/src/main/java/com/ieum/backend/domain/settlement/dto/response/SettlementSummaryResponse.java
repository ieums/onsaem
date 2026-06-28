package com.ieum.backend.domain.settlement.dto.response;

public record SettlementSummaryResponse(
        Long tutorId,
        long totalAmount,       // 누적 총 정산 금액(원) — 합계는 long으로(오버플로 방지)
        long transferredAmount, // 송금 완료된 총 금액
        long pendingAmount,     // 송금 대기 + 계산 완료 금액
        long settlementCount    // 정산 건수
) {}