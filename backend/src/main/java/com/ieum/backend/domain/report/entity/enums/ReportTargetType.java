package com.ieum.backend.domain.report.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 신고 대상 유형 (targetId와 함께 다형 참조) */
@Getter
@RequiredArgsConstructor
public enum ReportTargetType {

    TUTOR("강사"),
    STUDENT("학생"),
    LESSON("강의"),
    REVIEW("리뷰");

    private final String displayName;
}
