package com.ieum.backend.domain.payment.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum PaymentMethod {

    KAKAOPAY("카카오페이"),
    TOSSPAY("토스페이"),
    NAVERPAY("네이버페이"),
    CARD("신용/체크카드"),
    BANK_TRANSFER("계좌이체");

    private final String displayName;

    /**
     * 클라이언트에서 보낸 method 문자열 → enum
     */
    public static PaymentMethod fromString(String method) {
        if (method == null) return CARD;
        try {
            return PaymentMethod.valueOf(method.toUpperCase());
        } catch (IllegalArgumentException e) {
            return CARD;
        }
    }
}