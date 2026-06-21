package com.ieum.backend.domain.report.service;

import com.ieum.backend.domain.report.dto.request.CreateReportRequest;
import com.ieum.backend.domain.report.dto.response.ReportResponse;
import com.ieum.backend.domain.report.entity.Report;
import com.ieum.backend.domain.report.repository.ReportRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReportService {

    private final ReportRepository reportRepository;

    /**
     * 신고 접수 — PENDING으로 저장. (v1: 접수까지만, 운영자 처리는 추후)
     * 같은 신고자가 같은 대상·사유로 중복 신고하면 차단.
     */
    @Transactional
    public ReportResponse create(CreateReportRequest request) {
        // 1차 방어 (친절한 에러)
        boolean dup = reportRepository.existsByReporterIdAndTargetTypeAndTargetIdAndReason(
                request.getReporterId(), request.getTargetType(),
                request.getTargetId(), request.getReason());
        if (dup) {
            throw BusinessException.conflict("이미 동일한 사유로 신고했습니다.");
        }

        Report report = Report.builder()
                .reporterId(request.getReporterId())
                .reporterType(request.getReporterType())
                .targetType(request.getTargetType())
                .targetId(request.getTargetId())
                .lessonId(request.getLessonId())
                .reason(request.getReason())
                .description(request.getDescription())
                .build();

        // 2차 방어 (동시 신고도 UNIQUE가 막음)
        try {
            reportRepository.saveAndFlush(report);
        } catch (DataIntegrityViolationException e) {
            throw BusinessException.conflict("이미 동일한 사유로 신고했습니다.", e);
        }
        return ReportResponse.from(report);
    }
}
