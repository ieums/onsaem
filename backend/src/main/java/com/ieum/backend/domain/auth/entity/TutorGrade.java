package com.ieum.backend.domain.auth.entity;

/** 강사 등급. 가입 시 ROOKIE 로 시작, 상향은 운영 정책에 따름. 결제 도메인이 등급별 수수료를 적용 */
public enum TutorGrade {
    ROOKIE,
    JUNIOR,
    SENIOR,
    MASTER
}