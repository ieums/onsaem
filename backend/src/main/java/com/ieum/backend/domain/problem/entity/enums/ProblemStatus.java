package com.ieum.backend.domain.problem.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ProblemStatus {
    PENDING("매칭 대기"),       // 학생 등록 / 탐색 중
    MATCHED("매칭 완료"),       // 강사 매칭
    RESOLVED("풀이 완료"),      // 강의 끝
    EXPIRED("만료됨"),          // 탐색 마감(deadline)까지 강사 못 구함 → 자동 만료
    CANCELED("취소됨");          // 학생이 직접 취소

    private final String displayName;
}