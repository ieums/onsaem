package com.ieum.backend.domain.settlement.policy;

/**
 * 정산 정책 상수.
 * 분배 비율·환산 단가를 한곳에 모아 매직넘버를 제거한다.
 */
public final class SettlementPolicy {

    private SettlementPolicy() {
    }

    /** 플랫폼 수수료 비율 (총 코인의 20%) */
    public static final double PLATFORM_FEE_RATE = 0.2;

    /** 코인 → 현금 환산 단가 (1코인 = 100원) */
    public static final int COIN_TO_WON = 100;

    /** 정산 분배 결과 (수수료 코인 / 강사 코인 / 강사 현금) */
    public record Distribution(int platformFeeCoin, int tutorCoin, int tutorAmount) {
    }

    /**
     * 총 코인을 플랫폼/강사 몫으로 분배.
     * 수수료를 먼저 떼고 나머지를 강사 몫으로 둬 합이 항상 totalCoin과 일치(잔액 보존).
     */
    public static Distribution distribute(int totalCoin) {
        int platformFeeCoin = (int) (totalCoin * PLATFORM_FEE_RATE);
        int tutorCoin = totalCoin - platformFeeCoin;
        int tutorAmount = tutorCoin * COIN_TO_WON;
        return new Distribution(platformFeeCoin, tutorCoin, tutorAmount);
    }
}
