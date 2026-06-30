package com.ieum.backend.domain.problem.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum Subject {
    KOREAN("국어"),
    MATH("수학"),
    ENGLISH("영어"),
    SOCIAL("사회"),
    SCIENCE("과학"),
    UNKNOWN("미분류");

    private final String displayName;

    /**
     * enum 이름("KOREAN") 또는 한글 표시명("국어") 어느 쪽이 와도 매핑한다.
     * 강사 가입 데이터가 둘 중 무엇으로 저장됐든 매칭이 깨지지 않도록 한다.
     * 매칭 실패 시 null 반환(호출부에서 필터링).
     */
    public static Subject fromAny(String value) {
        if (value == null) return null;
        String v = value.trim();
        for (Subject s : values()) {
            if (s.name().equalsIgnoreCase(v) || s.displayName.equals(v)) {
                return s;
            }
        }
        return null;
    }

    /**
     * 저장된 원문(enum 이름/한글 무관)을 한글 표시명으로 변환한다.
     * 매핑되는 enum이 없으면 원문을 그대로 반환(데이터 보존). null이면 null.
     */
    public static String displayNameOf(String value) {
        if (value == null) return null;
        Subject s = fromAny(value);
        return s != null ? s.displayName : value;
    }
}