package com.ieum.backend.domain.lesson.dto;

import java.time.LocalDateTime;

/**
 * 강의 연장 응답.
 * - extended=true  : 연장 성공, endsAt이 갱신됨
 * - extended=false : 코인 부족 → 프론트가 shortfallCoin만큼 충전 후 재시도
 */
public record ExtendLessonResponse(
        boolean extended,
        LocalDateTime endsAt,   // 연장 성공 시 새 종료예정시각 (실패 시 기존 값)
        int requiredCoin,       // 이번 연장에 필요한 코인
        int shortfallCoin       // 부족한 코인 (성공 시 0)
) {
    public static ExtendLessonResponse extended(LocalDateTime endsAt, int requiredCoin) {
        return new ExtendLessonResponse(true, endsAt, requiredCoin, 0);
    }

    public static ExtendLessonResponse needsPayment(LocalDateTime endsAt, int requiredCoin, int shortfallCoin) {
        return new ExtendLessonResponse(false, endsAt, requiredCoin, shortfallCoin);
    }
}
