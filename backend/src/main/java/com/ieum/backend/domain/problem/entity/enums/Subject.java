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
}