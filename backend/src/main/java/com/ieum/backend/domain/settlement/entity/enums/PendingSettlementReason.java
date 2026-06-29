package com.ieum.backend.domain.settlement.entity.enums;

/**
 * 완료됐지만 아직 정산 레코드가 만들어지지 않은 강의의 '보류 사유'.
 * (정산은 종료 24h 경과 + 신고 없음일 때 스케줄러가 생성한다.)
 */
public enum PendingSettlementReason {
    /** 수업 종료 후 24시간 정산 대기 중 — 경과하면 자동 정산. */
    WAITING_PERIOD,
    /** 신고 처리 중이라 정산 보류 — 처리 완료 후 정산. */
    REPORT_HOLD,
    /** 대기/신고 조건은 끝났고 곧(다음 스케줄 틱) 자동 정산될 예정. */
    PROCESSING
}
