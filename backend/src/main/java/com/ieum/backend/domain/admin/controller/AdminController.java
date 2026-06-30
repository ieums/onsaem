package com.ieum.backend.domain.admin.controller;

import com.ieum.backend.domain.aitutor.entity.AiTutorMessageRole;
import com.ieum.backend.domain.aitutor.repository.AiTutorMessageRepository;
import com.ieum.backend.domain.auth.entity.Student;
import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.StudentRepository;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscriptStatus;
import com.ieum.backend.domain.lessonreview.repository.LessonTranscriptRepository;
import com.ieum.backend.domain.payment.entity.enums.PaymentStatus;
import com.ieum.backend.domain.payment.repository.PaymentRepository;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import com.ieum.backend.domain.report.entity.Report;
import com.ieum.backend.domain.report.entity.enums.ReportStatus;
import com.ieum.backend.domain.report.repository.ReportRepository;
import com.ieum.backend.domain.settlement.entity.Settlement;
import com.ieum.backend.domain.settlement.entity.enums.SettlementStatus;
import com.ieum.backend.domain.settlement.repository.SettlementRepository;
import com.ieum.backend.domain.settlement.service.SettlementService;
import com.ieum.backend.domain.report.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

/**
 * 관리자 콘솔(Thymeleaf 서버렌더).
 * - GET: 로그인/대시보드/신고 목록·상세/정산 목록·상세.
 * - POST: 신고 상태변경(reviewing/resolve/reject/uphold), 정산 송금완료/실패/재시도/취소.
 * 모든 /admin/** 은 SecurityConfig(adminFilterChain)에서 ROLE_ADMIN + 세션 폼로그인 + CSRF로 보호.
 */
@Controller
@RequiredArgsConstructor
public class AdminController {

    private final ReportService reportService;
    private final SettlementService settlementService;
    private final ReportRepository reportRepository;
    private final TutorRepository tutorRepository;
    private final StudentRepository studentRepository;
    private final LessonRepository lessonRepository;
    private final PaymentRepository paymentRepository;
    private final ProblemRepository problemRepository;
    private final AiTutorMessageRepository aiTutorMessageRepository;
    private final LessonTranscriptRepository lessonTranscriptRepository;

    // ── 화면(GET) ──

    @GetMapping("/admin/login")
    public String login() {
        return "admin/login";
    }

    @GetMapping("/admin")
    public String dashboard(Model model) {
        // 신고 상태별 count
        model.addAttribute("reportPending", reportRepository.countByStatus(ReportStatus.PENDING));
        model.addAttribute("reportReviewing", reportRepository.countByStatus(ReportStatus.REVIEWING));
        model.addAttribute("reportResolved", reportRepository.countByStatus(ReportStatus.RESOLVED));
        model.addAttribute("reportRejected", reportRepository.countByStatus(ReportStatus.REJECTED));

        // 정산 상태별 합계/건수
        model.addAttribute("settlementStats", List.of(
                statRow(SettlementStatus.CALCULATED),
                statRow(SettlementStatus.PENDING),
                statRow(SettlementStatus.TRANSFERRED),
                statRow(SettlementStatus.FAILED),
                statRow(SettlementStatus.CANCELED)
        ));

        // 회원 수(학생/강사)
        model.addAttribute("studentCount", studentRepository.count());
        model.addAttribute("tutorCount", tutorRepository.count());

        // 강의 수(상태별)
        model.addAttribute("lessonWaiting", lessonRepository.countByStatus(Lesson.LessonStatus.WAITING));
        model.addAttribute("lessonActive", lessonRepository.countByStatus(Lesson.LessonStatus.ACTIVE));
        model.addAttribute("lessonCompleted", lessonRepository.countByStatus(Lesson.LessonStatus.COMPLETED));
        model.addAttribute("lessonCanceled", lessonRepository.countByStatus(Lesson.LessonStatus.CANCELED));

        // 결제/매출 합계(완료 기준)
        model.addAttribute("paymentCompletedCount", paymentRepository.countByStatus(PaymentStatus.COMPLETED));
        model.addAttribute("paymentRevenue", paymentRepository.sumAmountByStatus(PaymentStatus.COMPLETED));

        // 완료 강의 평균 수업시간(분) — 데이터 없으면 null
        Double avgMin = lessonRepository.avgDurationMinutes(Lesson.LessonStatus.COMPLETED.name());
        model.addAttribute("avgLessonMinutes", avgMin == null ? null : Math.round(avgMin));

        // 강의 상태 분포 차트용(최대값 기준 막대 비율은 템플릿에서 계산)
        long lw = lessonRepository.countByStatus(Lesson.LessonStatus.WAITING);
        long la = lessonRepository.countByStatus(Lesson.LessonStatus.ACTIVE);
        long lc = lessonRepository.countByStatus(Lesson.LessonStatus.COMPLETED);
        long lx = lessonRepository.countByStatus(Lesson.LessonStatus.CANCELED);
        long lessonMax = Math.max(Math.max(lw, la), Math.max(lc, lx));
        model.addAttribute("lessonChart", List.of(
                new BarRow("대기", "WAITING", lw),
                new BarRow("진행중", "ACTIVE", la),
                new BarRow("완료", "COMPLETED", lc),
                new BarRow("취소", "CANCELED", lx)
        ));
        model.addAttribute("lessonChartMax", lessonMax == 0 ? 1 : lessonMax);

        // Gemini 근사 사용량(정확한 토큰/비용 아님)
        model.addAttribute("geminiOcrApprox", problemRepository.count());                                  // 문제 수 ≈ OCR 호출
        model.addAttribute("geminiChatApprox", aiTutorMessageRepository.countByRole(AiTutorMessageRole.AI)); // AI 응답 수 ≈ 챗 호출
        model.addAttribute("geminiSummaryApprox",
                lessonTranscriptRepository.countByStatus(LessonTranscriptStatus.COMPLETED));               // 전사 완료 ≈ 요약 호출
        return "admin/dashboard";
    }

    @GetMapping("/admin/reports")
    public String reports(@RequestParam(required = false) ReportStatus status,
                          @RequestParam(defaultValue = "0") int page,
                          Model model) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), PAGE_SIZE);
        Page<Report> reports = reportService.getReportsForAdmin(status, pageable);
        List<ReportRow> rows = reports.getContent().stream().map(this::toReportRow).toList();
        model.addAttribute("rows", rows);
        addPaging(model, reports);
        model.addAttribute("status", status);
        model.addAttribute("statuses", ReportStatus.values());
        return "admin/reports";
    }

    @GetMapping("/admin/reports/{id}")
    public String reportDetail(@PathVariable Long id, Model model) {
        Report report = reportService.getReportForAdmin(id);
        model.addAttribute("report", report);
        model.addAttribute("reporterName", accountName(report.getReporterType().name(), report.getReporterId()));
        model.addAttribute("targetName", accountName(report.getTargetType().name(), report.getTargetId()));
        return "admin/report-detail";
    }

    @GetMapping("/admin/settlements")
    public String settlements(@RequestParam(required = false) SettlementStatus status,
                              @RequestParam(defaultValue = "0") int page,
                              Model model) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), PAGE_SIZE);
        Page<Settlement> pageData = settlementService.getSettlementsForAdmin(status, pageable);
        List<SettlementRow> rows = pageData.getContent().stream().map(this::toSettlementRow).toList();
        model.addAttribute("rows", rows);
        addPaging(model, pageData);

        // 상단 요약 — 상태 × 건수 × 합계 (대시보드 settlementStats 패턴 재사용). 송금대기(PENDING) 강조.
        model.addAttribute("settlementStats", List.of(
                statRow(SettlementStatus.CALCULATED),
                statRow(SettlementStatus.PENDING),
                statRow(SettlementStatus.TRANSFERRED),
                statRow(SettlementStatus.FAILED),
                statRow(SettlementStatus.CANCELED)
        ));

        model.addAttribute("status", status);
        model.addAttribute("statuses", SettlementStatus.values());
        return "admin/settlements";
    }

    @GetMapping("/admin/settlements/{id}")
    public String settlementDetail(@PathVariable Long id, Model model) {
        Settlement s = settlementService.getSettlementForAdmin(id);
        model.addAttribute("s", s);
        Tutor tutor = tutorRepository.findById(s.getTutorId()).orElse(null);
        model.addAttribute("tutor", tutor);
        return "admin/settlement-detail";
    }

    // ── 신고 처리(POST) ──

    @PostMapping("/admin/reports/{id}/reviewing")
    public String reviewing(@PathVariable Long id,
                            @AuthenticationPrincipal UserDetails admin,
                            RedirectAttributes ra) {
        reportService.markReviewing(id, adminId(admin));
        ra.addFlashAttribute("msg", "신고 #" + id + " 를 검토중으로 변경했습니다.");
        return "redirect:/admin/reports";
    }

    @PostMapping("/admin/reports/{id}/resolve")
    public String resolve(@PathVariable Long id,
                          @AuthenticationPrincipal UserDetails admin,
                          RedirectAttributes ra) {
        reportService.resolve(id, adminId(admin));
        ra.addFlashAttribute("msg", "신고 #" + id + " 를 처리완료(무효)로 변경했습니다. 출금 보류가 해제됩니다.");
        return "redirect:/admin/reports";
    }

    @PostMapping("/admin/reports/{id}/reject")
    public String reject(@PathVariable Long id,
                         @AuthenticationPrincipal UserDetails admin,
                         RedirectAttributes ra) {
        reportService.reject(id, adminId(admin));
        ra.addFlashAttribute("msg", "신고 #" + id + " 를 반려했습니다. 출금 보류가 해제됩니다.");
        return "redirect:/admin/reports";
    }

    @PostMapping("/admin/reports/{id}/uphold")
    public String uphold(@PathVariable Long id,
                         @AuthenticationPrincipal UserDetails admin,
                         RedirectAttributes ra) {
        reportService.uphold(id, adminId(admin));
        ra.addFlashAttribute("msg", "신고 #" + id + " 를 인정 처리했습니다. 해당 강의 정산을 취소했습니다(환불은 별도 진행).");
        return "redirect:/admin/reports";
    }

    // ── 정산 처리(POST) ──

    @PostMapping("/admin/settlements/{id}/complete")
    public String complete(@PathVariable Long id, RedirectAttributes ra) {
        settlementService.completeWithdraw(id);
        ra.addFlashAttribute("msg", "정산 #" + id + " 송금 완료 처리했습니다.");
        return "redirect:/admin/settlements";
    }

    @PostMapping("/admin/settlements/{id}/fail")
    public String fail(@PathVariable Long id, RedirectAttributes ra) {
        settlementService.failWithdraw(id);
        ra.addFlashAttribute("msg", "정산 #" + id + " 송금 실패 처리했습니다.");
        return "redirect:/admin/settlements";
    }

    @PostMapping("/admin/settlements/{id}/retry")
    public String retry(@PathVariable Long id, RedirectAttributes ra) {
        settlementService.retryWithdraw(id);
        ra.addFlashAttribute("msg", "정산 #" + id + " 를 재시도(정산 계산 완료)로 되돌렸습니다.");
        return "redirect:/admin/settlements";
    }

    @PostMapping("/admin/settlements/{id}/cancel")
    public String cancel(@PathVariable Long id, RedirectAttributes ra) {
        settlementService.cancelSettlement(id);
        ra.addFlashAttribute("msg", "정산 #" + id + " 를 취소했습니다.");
        return "redirect:/admin/settlements";
    }

    // ── 내부 유틸 ──

    /** 관리자 목록 페이지 크기. */
    private static final int PAGE_SIZE = 20;

    /** Page 의 현재/전체 페이지 정보를 모델에 담아 템플릿 페이지네이션에 사용. */
    private static void addPaging(Model model, Page<?> p) {
        model.addAttribute("pageNo", p.getNumber());
        model.addAttribute("totalPages", p.getTotalPages());
        model.addAttribute("totalElements", p.getTotalElements());
        model.addAttribute("hasPrev", p.hasPrevious());
        model.addAttribute("hasNext", p.hasNext());
    }

    private StatRow statRow(SettlementStatus status) {
        SettlementRepository.SettlementStatusAggregate agg = settlementService.aggregateByStatus(status);
        long cnt = agg == null || agg.getCnt() == null ? 0L : agg.getCnt();
        long amount = agg == null || agg.getAmount() == null ? 0L : agg.getAmount();
        return new StatRow(status, status.getDisplayName(), cnt, amount);
    }

    /** admin username(InMemory 계정)을 식별자로 사용 — 숫자 id가 없으므로 null. handledBy는 v1에서 null 허용. */
    private Long adminId(UserDetails admin) {
        return null;
    }

    private ReportRow toReportRow(Report r) {
        return new ReportRow(
                r.getId(),
                r.getStatus(),
                r.getReporterType().getDisplayName(),
                accountName(r.getReporterType().name(), r.getReporterId()),
                r.getTargetType().getDisplayName(),
                accountName(r.getTargetType().name(), r.getTargetId()),
                r.getLessonId(),
                r.getCreatedAt()
        );
    }

    private SettlementRow toSettlementRow(Settlement s) {
        String tutorName = tutorRepository.findById(s.getTutorId())
                .map(Tutor::getName).orElse(null);
        return new SettlementRow(
                s.getId(),
                s.getStatus(),
                tutorName,
                s.getSubject(),
                s.getTutorAmount(),
                s.getLessonId(),
                s.getCreatedAt()
        );
    }

    /** 신고자/대상의 표시 이름(학생/강사 계정에서 join). 강의·리뷰 등은 이름이 없으므로 null. */
    private String accountName(String type, Long id) {
        if (id == null) return null;
        return switch (type) {
            case "TUTOR" -> tutorRepository.findById(id).map(Tutor::getName).orElse(null);
            case "STUDENT" -> studentRepository.findById(id).map(Student::getName).orElse(null);
            default -> null;
        };
    }

    // ── 템플릿 바인딩용 뷰 모델 ──

    public record ReportRow(Long id, ReportStatus status, String reporterType, String reporterName,
                            String targetType, String targetName, Long lessonId,
                            java.time.LocalDateTime createdAt) {}

    public record SettlementRow(Long id, SettlementStatus status, String tutorName, String subject,
                                Integer tutorAmount, Long lessonId, java.time.LocalDateTime createdAt) {}

    public record StatRow(SettlementStatus status, String displayName, long count, long amount) {}

    /** 대시보드 CSS 막대그래프용 행. statusClass 는 badge 색상 클래스로 재사용. */
    public record BarRow(String label, String statusClass, long count) {}
}
