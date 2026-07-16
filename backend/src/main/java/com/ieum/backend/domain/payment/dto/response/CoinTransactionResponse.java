package com.ieum.backend.domain.payment.dto.response;

import com.ieum.backend.domain.payment.entity.CoinTransaction;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class CoinTransactionResponse {

    private Long id;
    private String type;
    private String typeDisplayName;
    private Integer amount;
    private Integer balanceAfter;
    private String description;
    private LocalDateTime createdAt;

    public static CoinTransactionResponse from(CoinTransaction tx) {
        return CoinTransactionResponse.builder()
                .id(tx.getId())
                .type(tx.getType().name())
                .typeDisplayName(tx.getType().getDisplayName())
                .amount(tx.getAmount())
                .balanceAfter(tx.getBalanceAfter())
                .description(tx.getDescription())
                .createdAt(tx.getCreatedAt())
                .build();
    }
}