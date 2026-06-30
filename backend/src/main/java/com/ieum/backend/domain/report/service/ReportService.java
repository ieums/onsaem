package com.ieum.backend.domain.report.service;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.report.dto.request.CreateReportRequest;
import com.ieum.backend.domain.report.dto.response.ReportResponse;
import com.ieum.backend.domain.report.entity.Report;
import com.ieum.backend.domain.report.entity.enums.ReportTargetType;
import com.ieum.backend.domain.report.entity.enums.ReporterType;
import com.ieum.backend.domain.report.repository.ReportRepository;
import com.ieum.backend.domain.settlement.service.SettlementService;
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
    private final SettlementService settlementService; // 신고 인정 시 정산 취소 연동

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

    // ── 관리자 콘솔: 조회 ──

    /** 관리자 신고 목록 — status가 null이면 전체, 아니면 상태 필터(최신순). */
    public java.util.List<Report> getReportsForAdmin(
            com.ieum.backend.domain.report.entity.enums.ReportStatus status) {
        return (status == null)
                ? reportRepository.findAllByOrderByCreatedAtDesc()
                : reportRepository.findByStatusOrderByCreatedAtDesc(status);
    }

    /** 관리자 신고 목록(페이지) — status가 null이면 전체, 아니면 상태 필터(최신순). */
    public org.springframework.data.domain.Page<Report> getReportsForAdmin(
            com.ieum.backend.domain.report.entity.enums.ReportStatus status,
            org.springframework.data.domain.Pageable pageable) {
        return (status == null)
                ? reportRepository.findAllByOrderByCreatedAtDesc(pageable)
                : reportRepository.findByStatusOrderByCreatedAtDesc(status, pageable);
    }

    /** 관리자 신고 상세 — 엔티티 그대로(템플릿이 join 정보를 별도 조회). */
    public Report getReportForAdmin(Long reportId) {
        return reportRepository.findById(reportId)
                .orElseThrow(() -> BusinessException.notFound("신고를 찾을 수 없습니다. reportId: " + reportId));
    }

    // ── 관리자 콘솔: 상태 변경(부수효과 포함) ──

    /** PENDING → REVIEWING (검토중). */
    @Transactional
    public void markReviewing(Long reportId, Long adminId) {
        getReportForAdmin(reportId).markReviewing(adminId);
    }

    /**
     * 처리완료(정상 수업 확인 = 신고 무효) → RESOLVED.
     * 부수효과: 그 강의의 출금 보류가 풀린다(다음 finalize 틱에 정산이 자동 생성되므로 강제 생성 불필요).
     */
    @Transactional
    public void resolve(Long reportId, Long adminId) {
        getReportForAdmin(reportId).resolve(adminId);
    }

    /**
     * 반려(신고 무효) → REJECTED.
     * 부수효과: resolve와 동일하게 출금 보류 해제(상태만 변경).
     */
    @Transactional
    public void reject(Long reportId, Long adminId) {
        getReportForAdmin(reportId).reject(adminId);
    }

    /**
     * 신고 인정(uphold) → 강의 환불 + 정산 취소.
     * - 정산 취소: settlementService.cancelByLesson(lessonId) (정산이 없으면 조용히 무시됨).
     * - 환불: 기존에 환불(코인 반환) 플로우가 별도로 존재하지 않으므로 여기서 임의 구현하지 않고
     *   TODO로 남긴다. (코인 hold 반환/PG 환불 연동은 별도 작업)
     * 신고는 RESOLVED로 마감한다.
     */
    @Transactional
    public void uphold(Long reportId, Long adminId) {
        Report report = getReportForAdmin(reportId);
        if (report.getLessonId() != null) {
            // 정산 취소(존재 시). 이미 송금 완료(TRANSFERRED)면 엔티티 cancel()이 막아 예외.
            settlementService.cancelByLesson(report.getLessonId());
        }
        // TODO: 환불(코인 hold 반환 / PG 결제 취소) 플로우 연동 — 현재 코드에 환불 진입점이 없어 미구현.
        report.uphold(adminId);
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
