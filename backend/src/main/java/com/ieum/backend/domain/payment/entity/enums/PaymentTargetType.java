package com.ieum.backend.domain.payment.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum PaymentTargetType {
    COIN_CHARGE("코인 충전"),
    SUBSCRIPTION("구독");

    private final String displayName;
}
