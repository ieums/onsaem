package com.ieum.backend.domain.report.service;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.report.dto.request.CreateReportRequest;
import com.ieum.backend.domain.report.dto.response.ReportResponse;
import com.ieum.backend.domain.report.entity.Report;
import com.ieum.backend.domain.report.entity.enums.ReportTargetType;
import com.ieum.backend.domain.report.entity.enums.ReporterType;
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
    private final LessonRepository lessonRepository;   // 강의 기반 신고의 당사자 검증용

    /**
     * 신고 접수 — PENDING으로 저장. (v1: 접수까지만, 운영자 처리는 추후)
     * 같은 신고자가 같은 대상·사유로 중복 신고하면 차단.
     */
    @Transactional
    public ReportResponse create(Long reporterId, ReporterType reporterType,
                                 CreateReportRequest request) {
        // 0. 강의 기반 신고면 신고자/대상이 그 강의의 실제 당사자(학생·강사)인지 검증
        validateLessonParties(reporterId, reporterType, request);

        // 1차 방어 (친절한 에러) — 대상당 1건
        boolean dup = reportRepository.existsByReporterIdAndTargetTypeAndTargetId(
                reporterId, request.getTargetType(), request.getTargetId());
        if (dup) {
            throw BusinessException.conflict("이미 신고한 대상입니다.");
        }

        Report report = Report.builder()
                .reporterId(reporterId)
                .reporterType(reporterType)
                .targetType(request.getTargetType())
                .targetId(request.getTargetId())
                .lessonId(request.getLessonId())
                .reasons(request.getReasons())
                .description(request.getDescription())
                .build();

        // 2차 방어 (동시 신고도 UNIQUE가 막음)
        try {
            reportRepository.saveAndFlush(report);
        } catch (DataIntegrityViolationException e) {
            throw BusinessException.conflict("이미 신고한 대상입니다.", e);
        }
        return ReportResponse.from(report);
    }

    /**
     * 내가 접수한 신고 목록 — 마이페이지 '내 신고 내역'.
     */
    public java.util.List<ReportResponse> getMyReports(Long reporterId) {
        return reportRepository.findByReporterIdOrderByCreatedAtDesc(reporterId)
                .stream()
                .map(ReportResponse::from)
                .toList();
    }

    /**
     * 강의 기반 신고의 ID 연결 검증.
     * lessonId가 있고 그 강의가 존재하면, 신고자/대상이 그 강의의 실제 학생·강사여야 한다.
     * (lessonId는 선택값 — 프로필 등 강의 무관 신고는 검증 대상이 아니므로 건너뛴다.)
     */
    private void validateLessonParties(Long reporterId, ReporterType reporterType,
                                       CreateReportRequest r) {
        if (r.getLessonId() == null) return;
        lessonRepository.findById(r.getLessonId()).ifPresent(lesson -> {
            Long reporterExpected = reporterType == ReporterType.STUDENT
                    ? lesson.getStudentId()
                    : lesson.getTutorId();
            if (!reporterId.equals(reporterExpected)) {
                throw BusinessException.badRequest("신고자가 해당 강의의 당사자가 아닙니다.");
            }
            if (r.getTargetType() == ReportTargetType.TUTOR
                    && !r.getTargetId().equals(lesson.getTutorId())) {
                throw BusinessException.badRequest("신고 대상이 해당 강의의 강사가 아닙니다.");
            }
            if (r.getTargetType() == ReportTargetType.STUDENT
                    && !r.getTargetId().equals(lesson.getStudentId())) {
                throw BusinessException.badRequest("신고 대상이 해당 강의의 학생이 아닙니다.");
            }
        });
    }
}
