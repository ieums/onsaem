package com.ieum.backend.domain.settlement.dto.response;

import com.ieum.backend.domain.settlement.entity.Settlement;
import com.ieum.backend.domain.settlement.entity.enums.SettlementStatus;

import java.time.LocalDateTime;

public record SettlementResponse(
        Long id,
        Long tutorId,
        Long lessonId,
        Integer totalCoin,
        Integer platformFeeCoin,
        Integer tutorCoin,
        Integer tutorAmount,
        SettlementStatus status,
        LocalDateTime createdAt,
        LocalDateTime transferredAt,
        // 그 강의에 처리 중인 신고가 있어 출금이 막힌 상태인지(프론트 배지/버튼 비활성용)
        boolean reportPending
) {
    public static SettlementResponse from(Settlement settlement) {
        return from(settlement, false);
    }

    public static SettlementResponse from(Settlement settlement, boolean reportPending) {
        return new SettlementResponse(
                settlement.getId(),
                settlement.getTutorId(),
                settlement.getLessonId(),
                settlement.getTotalCoin(),
                settlement.getPlatformFeeCoin(),
                settlement.getTutorCoin(),
                settlement.getTutorAmount(),
                settlement.getStatus(),
                settlement.getCreatedAt(),
                settlement.getTransferredAt(),
                reportPending
        );
    }
}