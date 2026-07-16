package com.ieum.backend.domain.settlement.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum SettlementStatus {

    CALCULATED("정산 계산 완료"),
    PENDING("송금 대기"),
    TRANSFERRED("송금 완료"),
    FAILED("송금 실패"),
    CANCELED("정산 취소");        // 강의 환불/취소로 정산 무효화 (롤백)

    private final String displayName;
}