package com.ieum.backend.domain.payment.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum TransactionType {

    CHARGE("코인 충전"),
    BONUS("보너스 지급"),
    SIGNUP_BONUS("가입 보너스"),
    HOLD("강의 임시 차감"),
    DEDUCT("강의 확정 차감"),
    RELEASE("홀드 해제"),
    REFUND("환불"),
    AI_USE("AI 튜터 사용");

    private final String displayName;
}