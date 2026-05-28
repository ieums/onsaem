package com.ieum.backend.domain.payment.dto.response;

import com.ieum.backend.domain.payment.entity.Settlement;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class SettlementResponse {

    private Long id;
    private Long tutorId;
    private Long lessonId;
    private Integer totalCoin;
    private Integer platformFeeCoin;
    private Integer tutorCoin;
    private Integer tutorAmount;
    private String status;
    private String statusDisplayName;
    private LocalDateTime createdAt;
    private LocalDateTime transferredAt;

    public static SettlementResponse from(Settlement s) {
        return SettlementResponse.builder()
                .id(s.getId())
                .tutorId(s.getTutorId())
                .lessonId(s.getLessonId())
                .totalCoin(s.getTotalCoin())
                .platformFeeCoin(s.getPlatformFeeCoin())
                .tutorCoin(s.getTutorCoin())
                .tutorAmount(s.getTutorAmount())
                .status(s.getStatus().name())
                .statusDisplayName(s.getStatus().getDisplayName())
                .createdAt(s.getCreatedAt())
                .transferredAt(s.getTransferredAt())
                .build();
    }
}