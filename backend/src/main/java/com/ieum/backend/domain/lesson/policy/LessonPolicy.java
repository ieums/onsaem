package com.ieum.backend.domain.lesson.policy;

import com.ieum.backend.global.exception.BusinessException;

import java.util.Set;

/**
 * 강의 과금 정책 상수.
 * 기본 30분 고정 블록 + 10/20/30분 연장.
 */
public final class LessonPolicy {

    private LessonPolicy() {
    }

    /** 기본 강의 시간 (분) */
    public static final int BASE_DURATION_MIN = 30;

    /** 기본 30분 강의 비용 (코인). 1코인=100원 → 5,000원 */
    public static final int BASE_COST_COIN = 50;

    /** 연장 포함 최대 총 강의 시간 (분). 토큰 90분 < 이 값이면 안전 */
    public static final int MAX_DURATION_MIN = 60;

    /** 선택 가능한 연장 단위 (분) */
    public static final Set<Integer> EXTENSION_OPTIONS_MIN = Set.of(10, 20, 30);

    /** 연장 10분당 코인 (10분=20 / 20분=40 / 30분=60). 1코인=100원 */
    public static final int EXTENSION_COIN_PER_10MIN = 20;

    /**
     * 연장 분(分)에 대한 코인 비용. 허용되지 않은 단위면 예외.
     */
    public static int extensionCost(int minutes) {
        if (!EXTENSION_OPTIONS_MIN.contains(minutes)) {
            throw BusinessException.badRequest(
                    "연장은 " + EXTENSION_OPTIONS_MIN + "분만 가능합니다. 요청: " + minutes);
        }
        return minutes / 10 * EXTENSION_COIN_PER_10MIN;
    }
}
