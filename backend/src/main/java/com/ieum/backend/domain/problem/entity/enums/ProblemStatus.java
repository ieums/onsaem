package com.ieum.backend.domain.problem.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ProblemStatus {
    PENDING("매칭 대기"),       // 학생 등록
    MATCHED("매칭 완료"),       // 강사 매칭
    RESOLVED("풀이 완료"),      // 강의 끝
    CANCELED("취소됨");          // 직접 취소, 시간 만료 등의 이유로 강사 매칭 안됨

    private final String displayName;
}