package com.ieum.backend.domain.admin.controller;

import com.ieum.backend.domain.admin.entity.Admin;
import com.ieum.backend.domain.admin.service.AdminAccountService;
import com.ieum.backend.domain.auth.entity.AccountStatus;
import com.ieum.backend.domain.auth.entity.Student;
import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.global.exception.BusinessException;
import com.ieum.backend.domain.auth.repository.StudentRepository;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.payment.entity.CoinTransaction;
import com.ieum.backend.domain.payment.entity.Payment;
import com.ieum.backend.domain.payment.entity.enums.PaymentStatus;
import com.ieum.backend.domain.payment.repository.CoinTransactionRepository;
import com.ieum.backend.domain.payment.repository.PaymentRepository;
import com.ieum.backend.domain.auth.entity.VerificationStatus;
import com.ieum.backend.domain.auth.service.TutorService;
import com.ieum.backend.domain.auth.service.VerificationDocumentStorage;
import com.ieum.backend.domain.payment.entity.Subscription;
import com.ieum.backend.domain.payment.service.CoinService;
import com.ieum.backend.domain.payment.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 관리자 콘솔 확장 — 관리자 계정/회원/강의/결제 화면.
 * 모두 조회 위주(읽기전용). 변경은 관리자 계정 추가(POST)만.
 * /admin/** 는 SecurityConfig(adminFilterChain)에서 ROLE_ADMIN + 세션 + CSRF 로 보호된다.
 */
@Controller
@RequiredArgsConstructor
public class AdminConsoleController {

    private final AdminAccountService adminAccountService;
    private final StudentRepository studentRepository;
    private final TutorRepository tutorRepository;
    private final LessonRepository lessonRepository;
    private final PaymentRepository paymentRepository;
    private final CoinTransactionRepository coinTransactionRepository;
    private final TutorService tutorService;
    private final VerificationDocumentStorage verificationStorage;
    private final CoinService coinService;
    private final SubscriptionService subscriptionService;

    // ─────────────── 1. 관리자 계정 ───────────────

    @GetMapping("/admin/accounts")
    @Transactional(readOnly = true)
    public String accounts(Model model) {
        model.addAttribute("admins", adminAccountService.findAll());
        return "admin/accounts";
    }

    @PostMapping("/admin/accounts")
    public String createAccount(@RequestParam String username,
                                @RequestParam String password,
                                RedirectAttributes ra) {
        try {
            Admin created = adminAccountService.create(username, password);
            ra.addFlashAttribute("msg", "관리자 '" + created.getUsername() + "' 를 추가했습니다.");
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("err", e.getMessage());
        }
        return "redirect:/admin/accounts";
    }

    // ─────────────── 2. 회원 관리 (학생 / 강사 분리) ───────────────

    /** 기존 통합 /admin/members 는 학생 목록으로 리다이렉트(레거시 링크 호환). */
    @GetMapping("/admin/members")
    public String membersLegacyRedirect() {
        return "redirect:/admin/students";
    }

    @GetMapping("/admin/students")
    @Transactional(readOnly = true)
    public String students(@RequestParam(required = false) String q,
                           @RequestParam(defaultValue = "0") int page,
                           Model model) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), PAGE_SIZE);
        boolean hasQuery = q != null && !q.isBlank();
        Page<Student> students = hasQuery
                ? studentRepository
                .findByNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByCreatedAtDesc(q, q, pageable)
                : studentRepository.findAllByOrderByCreatedAtDesc(pageable);
        model.addAttribute("students", students);
        addPaging(model, students);
        model.addAttribute("q", q);
        return "admin/students";
    }

    @GetMapping("/admin/tutors")
    @Transactional(readOnly = true)
    public String tutors(@RequestParam(required = false) String q,
                         @RequestParam(defaultValue = "0") int page,
                         Model model) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), PAGE_SIZE);
        boolean hasQuery = q != null && !q.isBlank();
        Page<Tutor> tutors = hasQuery
                ? tutorRepository
                .findByNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByCreatedAtDesc(q, q, pageable)
                : tutorRepository.findAllByOrderByCreatedAtDesc(pageable);
        model.addAttribute("tutors", tutors);
        addPaging(model, tutors);
        model.addAttribute("q", q);
        return "admin/tutors";
    }

    @GetMapping("/admin/members/{role}/{id}")
    @Transactional(readOnly = true)
    public String memberDetail(@PathVariable String role, @PathVariable Long id,
                               @RequestParam(name = "txPage", defaultValue = "0") int txPage,
                               Model model) {
        String r = role.toUpperCase();
        model.addAttribute("role", r);
        // 상태 수정 드롭다운 — 탈퇴(WITHDRAWN)는 제외(별도 처리).
        model.addAttribute("statuses", java.util.List.of(
                AccountStatus.ACTIVE, AccountStatus.INACTIVE, AccountStatus.SUSPENDED));
        if ("TUTOR".equals(r)) {
            Tutor tutor = tutorRepository.findById(id).orElse(null);
            model.addAttribute("tutor", tutor);
        } else {
            Student student = studentRepository.findById(id).orElse(null);
            model.addAttribute("student", student);
            if (student != null) {
                // 이 학생의 코인 거래내역 — 페이지(10건씩). 잔액은 최신 1건의 balanceAfter.
                var txPageData = coinTransactionRepository.findByStudentIdOrderByCreatedAtDesc(
                        id, PageRequest.of(Math.max(txPage, 0), 10));
                model.addAttribute("coinTx", txPageData.getContent());
                model.addAttribute("txPageNo", txPageData.getNumber());
                model.addAttribute("txTotalPages", txPageData.getTotalPages());
                model.addAttribute("txHasPrev", txPageData.hasPrevious());
                model.addAttribute("txHasNext", txPageData.hasNext());
                model.addAttribute("coinBalance", coinTransactionRepository
                        .findFirstByStudentIdOrderByCreatedAtDesc(id)
                        .map(CoinTransaction::getBalanceAfter).orElse(0));
            }
        }
        return "admin/member-detail";
    }

    /** 강사 인증상태 변경(인증완료/반려/대기). */
    @PostMapping("/admin/tutors/{id}/verification")
    public String updateTutorVerification(@PathVariable Long id,
                                          @RequestParam VerificationStatus status,
                                          RedirectAttributes ra) {
        try {
            tutorService.updateVerificationStatus(id, status);
            ra.addFlashAttribute("msg", "강사 인증상태를 '" + status.getDisplayName() + "' 로 변경했습니다.");
        } catch (RuntimeException e) {
            ra.addFlashAttribute("err", e.getMessage());
        }
        return "redirect:/admin/members/TUTOR/" + id;
    }

    /** 회원(학생) 정보 수정 — 이름·전화·상태. */
    @PostMapping("/admin/students/{id}/edit")
    @Transactional
    public String editStudent(@PathVariable Long id,
                              @RequestParam(required = false) String name,
                              @RequestParam(required = false) String phone,
                              @RequestParam(required = false) String status,
                              RedirectAttributes ra) {
        try {
            Student s = studentRepository.findById(id)
                    .orElseThrow(() -> BusinessException.notFound("학생을 찾을 수 없습니다."));
            s.updateProfile(name, phone, null, null);
            if (status != null && !status.isBlank()) {
                s.changeStatus(AccountStatus.valueOf(status));
            }
            ra.addFlashAttribute("msg", "학생 정보를 수정했습니다.");
        } catch (RuntimeException e) {
            ra.addFlashAttribute("err", e.getMessage());
        }
        return "redirect:/admin/members/STUDENT/" + id;
    }

    /** 회원(강사) 정보 수정 — 이름·전화·상태·학교·학과. */
    @PostMapping("/admin/tutors/{id}/edit")
    @Transactional
    public String editTutor(@PathVariable Long id,
                            @RequestParam(required = false) String name,
                            @RequestParam(required = false) String phone,
                            @RequestParam(required = false) String status,
                            @RequestParam(required = false) String school,
                            @RequestParam(required = false) String major,
                            RedirectAttributes ra) {
        try {
            Tutor t = tutorRepository.findById(id)
                    .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));
            t.updateProfile(name, phone, null, null);
            if (status != null && !status.isBlank()) {
                t.changeStatus(AccountStatus.valueOf(status));
            }
            t.updateTutorProfile(null,
                    school != null && !school.isBlank() ? school : null,
                    major != null && !major.isBlank() ? major : null,
                    null, null, null);
            ra.addFlashAttribute("msg", "강사 정보를 수정했습니다.");
        } catch (RuntimeException e) {
            ra.addFlashAttribute("err", e.getMessage());
        }
        return "redirect:/admin/members/TUTOR/" + id;
    }

    /** 관리자 코인 지급(보상·환불 등) → 해당 학생에게 BONUS 적립. */
    @PostMapping("/admin/students/{id}/coins")
    public String grantCoins(@PathVariable Long id,
                             @RequestParam int amount,
                             @RequestParam(required = false) String reason,
                             RedirectAttributes ra) {
        try {
            coinService.grantByAdmin(id, amount, reason);
            ra.addFlashAttribute("msg", amount + "코인을 지급했습니다.");
        } catch (RuntimeException e) {
            ra.addFlashAttribute("err", e.getMessage());
        }
        return "redirect:/admin/members/STUDENT/" + id;
    }

    /** 강사 학력 증빙 서류 열람 — 비공개 객체라 presigned URL로 리다이렉트(5분 유효). */
    @GetMapping("/admin/tutors/{id}/verification-document")
    @Transactional(readOnly = true)
    public String viewVerificationDocument(@PathVariable Long id, RedirectAttributes ra) {
        Tutor tutor = tutorRepository.findById(id).orElse(null);
        if (tutor == null || tutor.getVerificationDocumentUrl() == null) {
            ra.addFlashAttribute("err", "등록된 증빙 서류가 없습니다.");
            return "redirect:/admin/members/TUTOR/" + id;
        }
        return "redirect:" + verificationStorage.viewUrl(tutor.getVerificationDocumentUrl());
    }

    // ─────────────── 3. 강의/매칭 관리 ───────────────

    @GetMapping("/admin/lessons")
    @Transactional(readOnly = true)
    public String lessons(@RequestParam(required = false) Lesson.LessonStatus status,
                          @RequestParam(defaultValue = "0") int page,
                          Model model) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), PAGE_SIZE);
        Page<Lesson> pageData = status != null
                ? lessonRepository.findByStatusOrderByCreatedAtDesc(status, pageable)
                : lessonRepository.findAllByOrderByCreatedAtDesc(pageable);
        List<Lesson> list = pageData.getContent();

        // 강사/학생 이름 매핑(N+1 회피용 일괄 조회)
        Map<Long, String> tutorNames = nameMapTutors(list.stream().map(Lesson::getTutorId).filter(java.util.Objects::nonNull).distinct().toList());
        Map<Long, String> studentNames = nameMapStudents(list.stream().map(Lesson::getStudentId).filter(java.util.Objects::nonNull).distinct().toList());

        List<LessonRow> rows = list.stream().map(l -> new LessonRow(
                l.getId(), l.getStatus(),
                l.getStudentId(), studentNames.get(l.getStudentId()),
                l.getTutorId(), tutorNames.get(l.getTutorId()),
                l.getCoinCost(), l.getStartedAt(), l.getEndedAt(), l.getCreatedAt()
        )).toList();

        model.addAttribute("rows", rows);
        addPaging(model, pageData);
        model.addAttribute("status", status);
        model.addAttribute("statuses", Lesson.LessonStatus.values());
        return "admin/lessons";
    }

    // ─────────────── 4. 결제 / 코인 내역 (분리) ───────────────

    @GetMapping("/admin/payments")
    @Transactional(readOnly = true)
    public String payments(@RequestParam(required = false) String q,
                           @RequestParam(defaultValue = "0") int page, Model model) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), PAGE_SIZE);
        boolean hasQuery = q != null && !q.isBlank();
        Page<Payment> payments;
        if (hasQuery) {
            // 결제자(학생) 이름/이메일로 검색 → 해당 학생들의 결제만.
            List<Long> studentIds = studentRepository
                    .findTop200ByNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByCreatedAtDesc(q, q)
                    .stream().map(Student::getId).toList();
            payments = studentIds.isEmpty()
                    ? Page.empty(pageable)
                    : paymentRepository.findByStudentIdInOrderByCreatedAtDesc(studentIds, pageable);
        } else {
            payments = paymentRepository.findAllByOrderByCreatedAtDesc(pageable);
        }
        model.addAttribute("payments", payments);
        model.addAttribute("q", q);
        // 결제자 이름 표시용 (studentId → 이름). 결제는 학생만 하므로 전부 학생.
        model.addAttribute("payerNames", nameMapStudents(payments.stream()
                .map(Payment::getStudentId).filter(java.util.Objects::nonNull).distinct().toList()));
        addPaging(model, payments);
        model.addAttribute("revenue", paymentRepository.sumAmountByStatus(PaymentStatus.COMPLETED));
        return "admin/payments";
    }

    @GetMapping("/admin/coins")
    @Transactional(readOnly = true)
    public String coins(@RequestParam(defaultValue = "0") int page, Model model) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), PAGE_SIZE);
        Page<CoinTransaction> coinTx = coinTransactionRepository.findAllByOrderByCreatedAtDesc(pageable);
        model.addAttribute("coinTx", coinTx);
        addPaging(model, coinTx);
        return "admin/coins";
    }

    @GetMapping("/admin/subscriptions")
    @Transactional(readOnly = true)
    public String subscriptions(@RequestParam(defaultValue = "0") int page, Model model) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), PAGE_SIZE);
        Page<Subscription> subs = subscriptionService.getSubscriptionsForAdmin(pageable);
        model.addAttribute("subs", subs);
        model.addAttribute("subscriberNames", nameMapStudents(subs.stream()
                .map(Subscription::getStudentId).filter(java.util.Objects::nonNull).distinct().toList()));
        addPaging(model, subs);
        return "admin/subscriptions";
    }

    /** 구독 해지(자동갱신 OFF) — 기간까지 이용 유지. */
    @PostMapping("/admin/subscriptions/{id}/cancel")
    public String cancelSubscription(@PathVariable Long id, RedirectAttributes ra) {
        try {
            subscriptionService.cancelByAdmin(id);
            ra.addFlashAttribute("msg", "구독 #" + id + " 자동갱신을 해지했습니다(기간까지 이용 유지).");
        } catch (RuntimeException e) {
            ra.addFlashAttribute("err", e.getMessage());
        }
        return "redirect:/admin/subscriptions";
    }

    /** 구독 즉시 만료 — active=false + 활성 슬롯 해제. */
    @PostMapping("/admin/subscriptions/{id}/expire")
    public String expireSubscription(@PathVariable Long id, RedirectAttributes ra) {
        try {
            subscriptionService.expireByAdmin(id);
            ra.addFlashAttribute("msg", "구독 #" + id + " 을 즉시 만료했습니다.");
        } catch (RuntimeException e) {
            ra.addFlashAttribute("err", e.getMessage());
        }
        return "redirect:/admin/subscriptions";
    }

    // ─────────────── 내부 유틸 ───────────────

    /** 관리자 목록 페이지 크기. */
    static final int PAGE_SIZE = 20;

    /** Page 의 현재/전체 페이지 정보를 모델에 담아 템플릿 페이지네이션에 사용. */
    static void addPaging(Model model, Page<?> p) {
        model.addAttribute("pageNo", p.getNumber());
        model.addAttribute("totalPages", p.getTotalPages());
        model.addAttribute("totalElements", p.getTotalElements());
        model.addAttribute("hasPrev", p.hasPrevious());
        model.addAttribute("hasNext", p.hasNext());
    }

    private Map<Long, String> nameMapTutors(List<Long> ids) {
        Map<Long, String> map = new HashMap<>();
        if (ids.isEmpty()) return map;
        tutorRepository.findAllByIdIn(ids).forEach(t -> map.put(t.getId(), t.getName()));
        return map;
    }

    private Map<Long, String> nameMapStudents(List<Long> ids) {
        Map<Long, String> map = new HashMap<>();
        if (ids.isEmpty()) return map;
        studentRepository.findAllById(ids).forEach(s -> map.put(s.getId(), s.getName()));
        return map;
    }

    // ─────────────── 템플릿 바인딩용 뷰 모델 ───────────────

    public record LessonRow(Long id, Lesson.LessonStatus status,
                            Long studentId, String studentName,
                            Long tutorId, String tutorName,
                            Integer coinCost,
                            java.time.LocalDateTime startedAt,
                            java.time.LocalDateTime endedAt,
                            java.time.LocalDateTime createdAt) {}
}
