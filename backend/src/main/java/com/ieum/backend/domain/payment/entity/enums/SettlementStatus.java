package com.ieum.backend.domain.payment.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum SettlementStatus {

    CALCULATED("정산 계산 완료"),
    PENDING("송금 대기"),
    TRANSFERRED("송금 완료"),
    FAILED("송금 실패");

    private final String displayName;
}