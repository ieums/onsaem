package com.ieum.backend.domain.report.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/** 신고 사유 */
@Getter
@RequiredArgsConstructor
public enum ReportReason {

    // ── 사람(학생/강사) 관련 ──
    ABUSE("욕설/모욕"),
    NO_SHOW("노쇼/불참"),
    INAPPROPRIATE("부적절한 행동"),
    FRAUD("사기/허위"),
    SPAM("스팸/광고"),

    // ── 강의 관련 ──
    CONNECTION_ISSUE("연결/음성·영상 문제"),
    TECHNICAL_ISSUE("기술 오류(녹화·판서 등)"),
    LESSON_NOT_HELD("강의 미진행/중단"),

    // ── 공통 ──
    ETC("기타");

    private final String displayName;
}
