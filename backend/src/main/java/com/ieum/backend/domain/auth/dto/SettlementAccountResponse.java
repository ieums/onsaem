package com.ieum.backend.domain.auth.dto;

import com.ieum.backend.domain.auth.entity.Tutor;

/** 정산 계좌 조회 응답 (미등록 시 필드는 null) */
public record SettlementAccountResponse(String bank, String account, String holder) {

    public static SettlementAccountResponse from(Tutor tutor) {
        return new SettlementAccountResponse(
                tutor.getSettlementBank(),
                tutor.getSettlementAccount(),
                tutor.getSettlementHolder()
        );
    }
}
