package com.ieum.backend.domain.problem.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ExamType {
    SUNUNG("수능"),
    MOCK_EVALUATION("평가원 모의고사"),
    ACADEMIC_EVALUATION("학력평가"),
    EBS_SUNEUNG_TEUKGANG("EBS 수능특강"),
    EBS_SUNEUNG_WANSUNG("EBS 수능완성"),
    SCHOOL_INTERNAL("학교 내신"),
    ACADEMY("학원/N제"),
    OTHER("기타"),
    UNKNOWN("미분류");

    private final String displayName;
}