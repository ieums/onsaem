package com.ieum.backend.domain.problem.util;

import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;

public class DifficultyCalculator {

    /**
     * 시험유형에 따라 가중치를 다르게 적용
     *
     * 수능/모평/학력평가: 문항번호(30%) + 출제영역(20%) + 풀이단계(25%) + 개념복합도(15%) + 계산량(10%)
     * 그 외:             출제영역(25%) + 풀이단계(35%) + 개념복합도(25%) + 계산량(15%)
     */
    public static int calculateScore(ExamType examType,
                                     int problemNumberScore,
                                     int subjectAreaScore,
                                     int solutionStepsScore,
                                     int conceptComplexityScore,
                                     int calculationVolumeScore) {

        double total;

        if (isNumberedExam(examType)) {
            // 수능·모평·학력평가 → 문항번호 가중치 포함
            total = problemNumberScore     * 0.30
                    + subjectAreaScore       * 0.20
                    + solutionStepsScore     * 0.25
                    + conceptComplexityScore * 0.15
                    + calculationVolumeScore * 0.10;
        } else {
            // 그 외 → 문항번호 제외, 나머지 재분배
            total = subjectAreaScore       * 0.25
                    + solutionStepsScore     * 0.35
                    + conceptComplexityScore * 0.25
                    + calculationVolumeScore * 0.15;
        }

        return (int) Math.round(total);
    }

    /**
     * 종합 점수 → Difficulty Enum
     */
    public static Difficulty calculate(ExamType examType,
                                       int problemNumberScore,
                                       int subjectAreaScore,
                                       int solutionStepsScore,
                                       int conceptComplexityScore,
                                       int calculationVolumeScore) {

        int totalScore = calculateScore(examType, problemNumberScore,
                subjectAreaScore, solutionStepsScore,
                conceptComplexityScore, calculationVolumeScore);

        return Difficulty.fromScore(totalScore);
    }

    /**
     * 문항번호가 난이도 지표가 되는 시험인지 판별
     */
    private static boolean isNumberedExam(ExamType examType) {
        if (examType == null) return false;
        return examType == ExamType.SUNUNG
                || examType == ExamType.MOCK_EVALUATION
                || examType == ExamType.ACADEMIC_EVALUATION;
    }
}