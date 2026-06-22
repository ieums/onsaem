package com.ieum.backend.domain.lessonreview.controller;

/**
 * GET /lessons/{id}/summary-pdf 응답 DTO.
 * - COMPLETED: downloadUrl 에 1시간 유효 presigned URL 채워서 응답
 * - PROCESSING / FAILED / NOT_READY: downloadUrl null, message로 안내
 */
public record SummaryPdfResponse(
        String status,           // PROCESSING / COMPLETED / FAILED / NOT_READY
        String downloadUrl,      // COMPLETED 일 때만 채움
        String message
) {
}