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
        LocalDateTime transferredAt
) {
    public static SettlementResponse from(Settlement settlement) {
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
                settlement.getTransferredAt()
        );
    }
}