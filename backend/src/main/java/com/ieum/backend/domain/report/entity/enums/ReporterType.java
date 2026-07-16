package com.ieum.backend.domain.report.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 신고자 유형 (양방향) */
@Getter
@RequiredArgsConstructor
public enum ReporterType {

    STUDENT("학생"),
    TUTOR("강사");

    private final String displayName;
}
