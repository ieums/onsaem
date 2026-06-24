package com.ieum.backend.domain.report.controller;

import com.ieum.backend.domain.auth.entity.Role;
import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.report.dto.request.CreateReportRequest;
import com.ieum.backend.domain.report.dto.response.ReportResponse;
import com.ieum.backend.domain.report.entity.enums.ReporterType;
import com.ieum.backend.domain.report.service.ReportService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * 신고 (양방향: 학생↔강사). v1은 접수만.
 * 신고자(reporterId·reporterType)는 JWT 인증 주체에서 가져온다(본문 값 신뢰 X).
 */
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    /** 신고 접수 — POST /api/v1/reports */
    @PostMapping
    public ApiResponse<ReportResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestBody @Valid CreateReportRequest request) {
        ReporterType reporterType = principal.role() == Role.TUTOR
                ? ReporterType.TUTOR
                : ReporterType.STUDENT;
        return ApiResponse.ok("신고가 접수되었습니다.",
                reportService.create(principal.id(), reporterType, request));
    }

    /** 내 신고 내역 — GET /api/v1/reports/me */
    @GetMapping("/me")
    public ApiResponse<java.util.List<ReportResponse>> getMyReports(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(reportService.getMyReports(principal.id()));
    }
}
