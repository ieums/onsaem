package com.ieum.backend.domain.report.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 신고 처리 상태 (v1은 접수=PENDING까지만, 처리는 추후) */
@Getter
@RequiredArgsConstructor
public enum ReportStatus {

    PENDING("접수"),
    REVIEWING("검토중"),
    RESOLVED("처리완료"),
    REJECTED("반려");

    private final String displayName;
}
