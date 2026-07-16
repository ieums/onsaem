package com.ieum.backend.domain.auth.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 강사 등급. 가입 시 ROOKIE 로 시작, 상향은 운영 정책에 따름. 결제 도메인이 등급별 수수료를 적용 */
@Getter
@RequiredArgsConstructor
public enum TutorGrade {
    // 등급이 높을수록 정산 수수료가 낮다 — 최소 10%(마스터) ~ 최대 30%(루키).
    ROOKIE("루키", 30),
    JUNIOR("주니어", 25),
    SENIOR("시니어", 20),
    MASTER("마스터", 10);

    private final String displayName;
    /** 정산 플랫폼 수수료(%) — 등급별 차등. */
    private final int feePercent;
}
