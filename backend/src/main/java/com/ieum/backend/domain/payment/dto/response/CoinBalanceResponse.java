package com.ieum.backend.domain.payment.dto.response;

import com.ieum.backend.domain.payment.entity.CoinWallet;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class CoinBalanceResponse {

    private Long studentId;
    private Integer balance;
    private Integer availableBalance;

    public static CoinBalanceResponse from(CoinWallet wallet) {
        return CoinBalanceResponse.builder()
                .studentId(wallet.getStudentId())
                .balance(wallet.getBalance())
                .availableBalance(wallet.getAvailableBalance())
                .build();
    }
}