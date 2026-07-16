package com.ieum.backend.domain.payment.policy;

/**
 * 결제·코인 정책 상수.
 * 코드 곳곳에 흩어져 있던 정책 수치를 한곳에 모아 매직넘버를 제거한다.
 */
public final class PaymentPolicy {

    private PaymentPolicy() {
    }

    /** 가입 축하 보너스 코인 */
    public static final int SIGNUP_BONUS_COIN = 50;

    /** AI 튜터 1회 사용 비용 (코인) */
    public static final int AI_USE_COST_COIN = 3;

    /** 환불 가능 기간 (결제 완료 후 N일 이내) */
    public static final int REFUND_WINDOW_DAYS = 7;
}
