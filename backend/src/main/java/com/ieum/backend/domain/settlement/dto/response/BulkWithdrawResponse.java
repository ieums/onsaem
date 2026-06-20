package com.ieum.backend.domain.settlement.dto.response;

import java.util.List;

public record BulkWithdrawResponse(
        int settlementCount,        // 출금 요청한 정산 건수
        int totalAmount,            // 총 출금 금액
        List<SettlementResponse> settlements
) {}