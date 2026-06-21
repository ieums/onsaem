package com.ieum.backend.domain.report.controller;

import com.ieum.backend.domain.report.dto.request.CreateReportRequest;
import com.ieum.backend.domain.report.dto.response.ReportResponse;
import com.ieum.backend.domain.report.service.ReportService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 신고 (양방향: 학생↔강사). v1은 접수만.
 * reporterId는 인증 도입 전까지 본문으로 받음.
 */
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    /** 신고 접수 — POST /api/v1/reports */
    @PostMapping
    public ApiResponse<ReportResponse> create(@RequestBody @Valid CreateReportRequest request) {
        return ApiResponse.ok("신고가 접수되었습니다.", reportService.create(request));
    }
}
