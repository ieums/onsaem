package com.ieum.backend.domain.review.dto.response;

import java.util.Map;

/**
 * 튜터 리뷰 요약 (노출 리뷰 기준).
 * @param averageRating 평균 별점 (소수 1자리)
 * @param totalCount    총 리뷰 수
 * @param distribution  별점별 개수 (1~5 모두 포함, 없으면 0)
 */
public record ReviewSummaryResponse(
        Long tutorId,
        double averageRating,
        long totalCount,
        Map<Integer, Long> distribution
) {
}
