package com.ieum.backend.domain.settlement.policy;

/**
 * 정산 정책 상수.
 * 분배 비율·환산 단가를 한곳에 모아 매직넘버를 제거한다.
 */
public final class SettlementPolicy {

    private SettlementPolicy() {
    }

    /** 등급 미지정 등 기본 플랫폼 수수료(%) */
    public static final int DEFAULT_FEE_PERCENT = 20;

    /** 수수료 허용 범위(%) — 정책상 최소 10 ~ 최대 30. */
    public static final int MIN_FEE_PERCENT = 10;
    public static final int MAX_FEE_PERCENT = 30;

    /** 코인 → 현금 환산 단가 (1코인 = 100원) */
    public static final int COIN_TO_WON = 100;

    /** 정산 분배 결과 (수수료 코인 / 강사 코인 / 강사 현금) */
    public record Distribution(int platformFeeCoin, int tutorCoin, int tutorAmount) {
    }

    /** 기본 수수료(20%)로 분배. */
    public static Distribution distribute(int totalCoin) {
        return distribute(totalCoin, DEFAULT_FEE_PERCENT);
    }

    /**
     * 총 코인을 플랫폼/강사 몫으로 분배(수수료율 지정 — 등급별 차등).
     * 수수료를 먼저 떼고 나머지를 강사 몫으로 둬 합이 항상 totalCoin과 일치(잔액 보존).
     * feePercent는 정책 범위(10~30%)로 클램프해 잘못된 입력을 방어한다.
     */
    public static Distribution distribute(int totalCoin, int feePercent) {
        int rate = Math.max(MIN_FEE_PERCENT, Math.min(MAX_FEE_PERCENT, feePercent));
        // 정수 연산(double 절삭 편향 제거). 나머지를 강사 몫으로 둬 잔액 보존.
        int platformFeeCoin = totalCoin * rate / 100;
        int tutorCoin = totalCoin - platformFeeCoin;
        int tutorAmount = tutorCoin * COIN_TO_WON;
        return new Distribution(platformFeeCoin, tutorCoin, tutorAmount);
    }
}
