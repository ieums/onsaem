package com.ieum.backend.domain.auth.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 강사 등급. 가입 시 ROOKIE 로 시작, 상향은 운영 정책에 따름. 결제 도메인이 등급별 수수료를 적용 */
@Getter
@RequiredArgsConstructor
public enum TutorGrade {
    ROOKIE("루키"),
    JUNIOR("주니어"),
    SENIOR("시니어"),
    MASTER("마스터");

    private final String displayName;
}
