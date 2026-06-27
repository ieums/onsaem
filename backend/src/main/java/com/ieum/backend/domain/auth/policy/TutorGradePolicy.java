package com.ieum.backend.domain.auth.policy;

import com.ieum.backend.domain.auth.entity.TutorGrade;

import java.math.BigDecimal;

/**
 * 강사 등급 정책.
 * - 초기 등급: 경력연수(experienceYears) 2년 단위 매핑
 * - 최종 등급: max(경력기반, 실적기반) — 강등 없이 상향만(호출부에서 보장)
 */
public final class TutorGradePolicy {

    private TutorGradePolicy() {
    }

    /** 경력연수 → 초기 등급. null/0~1=ROOKIE, 2~3=JUNIOR, 4~5=SENIOR, 6+=MASTER. */
    public static TutorGrade initialGrade(Integer experienceYears) {
        int years = experienceYears == null ? 0 : Math.max(0, experienceYears);
        if (years >= 6) return TutorGrade.MASTER;
        if (years >= 4) return TutorGrade.SENIOR;
        if (years >= 2) return TutorGrade.JUNIOR;
        return TutorGrade.ROOKIE;
    }

    /** 경력·실적 종합 등급 = max(경력기반, 실적기반). */
    public static TutorGrade evaluate(Integer experienceYears, int lessonCount, BigDecimal ratingAvg) {
        TutorGrade byExp = initialGrade(experienceYears);
        TutorGrade byPerf = performanceGrade(lessonCount, ratingAvg);
        return byExp.ordinal() >= byPerf.ordinal() ? byExp : byPerf;
    }

    /** 실적 기반 등급 (수업수 & 평점). 평점 없으면 0 처리. */
    private static TutorGrade performanceGrade(int lessonCount, BigDecimal ratingAvg) {
        double rating = ratingAvg == null ? 0.0 : ratingAvg.doubleValue();
        if (lessonCount >= 80 && rating >= 4.6) return TutorGrade.MASTER;
        if (lessonCount >= 30 && rating >= 4.3) return TutorGrade.SENIOR;
        if (lessonCount >= 10 && rating >= 4.0) return TutorGrade.JUNIOR;
        return TutorGrade.ROOKIE;
    }
}