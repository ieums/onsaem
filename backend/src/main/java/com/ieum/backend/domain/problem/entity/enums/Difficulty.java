package com.ieum.backend.domain.problem.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum Difficulty {
    EASY("쉬움", 1),
    MEDIUM("보통", 2),
    HARD("어려움", 3);

    private final String displayName;
    private final int score;

    public static Difficulty fromScore(int totalScore) {
        if (totalScore <= 33) return EASY;
        if (totalScore <= 66) return MEDIUM;
        return HARD;
    }
}