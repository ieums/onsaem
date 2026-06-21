package com.ieum.backend.domain.report.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 신고 사유 */
@Getter
@RequiredArgsConstructor
public enum ReportReason {

    ABUSE("욕설/모욕"),
    NO_SHOW("노쇼/불참"),
    INAPPROPRIATE("부적절한 행동"),
    FRAUD("사기/허위"),
    SPAM("스팸/광고"),
    ETC("기타");

    private final String displayName;
}
