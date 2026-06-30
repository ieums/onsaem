package com.ieum.backend.domain.settlement.service;

import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import com.ieum.backend.domain.report.entity.enums.ReportStatus;
import com.ieum.backend.domain.report.repository.ReportRepository;
import com.ieum.backend.domain.settlement.dto.request.CalculateSettlementRequest;
import com.ieum.backend.domain.lesson.entity.Lesson.LessonStatus;
import com.ieum.backend.domain.settlement.dto.response.BulkWithdrawResponse;
import com.ieum.backend.domain.settlement.dto.response.PendingSettlementResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementSummaryResponse;
import com.ieum.backend.domain.settlement.entity.Settlement;
import com.ieum.backend.domain.settlement.entity.enums.PendingSettlementReason;
import com.ieum.backend.domain.settlement.entity.enums.SettlementStatus;
import com.ieum.backend.domain.settlement.policy.SettlementPolicy;
import com.ieum.backend.domain.settlement.repository.SettlementRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SettlementService {

    private final SettlementRepository settlementRepository;
    private final LessonRepository lessonRepository;   // 정산 대상 강사를 강의에서 권위있게 가져오기 위함
    private final TutorRepository tutorRepository;      // 출금 전 정산 계좌 등록 확인용
    private final ReportRepository reportRepository;    // 출금 전 신고 보류 확인용
    private final ProblemRepository problemRepository;  // 표시용 과목 조회

    /** 출금을 막아야 하는 '처리 중' 신고 상태. */
    private static final List<ReportStatus> OPEN_REPORTS =
            List.of(ReportStatus.PENDING, ReportStatus.REVIEWING);

    /** 그 강의에 처리 중(PENDING/REVIEWING)인 신고가 있는지 — 있으면 출금 보류. (단건용) */
    private boolean hasOpenReport(Long lessonId) {
        return reportRepository.existsByLessonIdAndStatusIn(lessonId, OPEN_REPORTS);
    }

    /** 여러 정산의 강의들 중 '열린 신고'가 있는 lessonId 집합을 한 번에 조회(N+1 제거). */
    private Set<Long> openReportLessonIds(List<Settlement> settlements) {
        List<Long> lessonIds = settlements.stream().map(Settlement::getLessonId).toList();
        if (lessonIds.isEmpty()) return Set.of();
        return new HashSet<>(reportRepository.findLessonIdsWithStatusIn(lessonIds, OPEN_REPORTS));
    }

    /**
     * 정산 계산 (강의 완료 시 호출).
     * 80%/20% 분배는 SettlementPolicy.distribute()가 계산하고, 엔티티는 결과만 저장한다.
     */
    @Transactional
    public SettlementResponse calculate(CalculateSettlementRequest request) {
        // 정산 대상 강사는 '강의의 실제 강사'를 권위로 삼는다.
        // (요청의 tutorId를 그대로 신뢰하면 엉뚱한 강사에게 정산될 수 있음 — tutor↔강의 연결 보장)
        Lesson lesson = lessonRepository.findById(request.getLessonId())
                .orElseThrow(() -> BusinessException.notFound(
                        "정산할 강의를 찾을 수 없습니다. lessonId: " + request.getLessonId()));
        Long tutorId = lesson.getTutorId();

        // 1차 방어: 이미 정산된 강의면 친절한 에러 (일반적인 단건 호출 경로)
        settlementRepository.findByLessonId(request.getLessonId())
                .ifPresent(existing -> {
                    throw BusinessException.conflict("이미 정산된 강의입니다. settlementId: " + existing.getId());
                });

        // 정산 금액은 요청값이 아니라 '강의의 실제 코인(coinCost)'을 권위로 삼는다.
        // (요청 totalCoin을 신뢰하면 외부에서 임의 금액으로 정산을 만들 수 있음 — 위조 방지)
        Integer coinCost = lesson.getCoinCost();
        if (coinCost == null || coinCost <= 0) {
            throw BusinessException.badRequest(
                    "정산할 코인 금액이 없습니다(과금 강의가 아님). lessonId: " + request.getLessonId());
        }

        // 표시용 과목(강의의 문제에서) — 조회 실패해도 정산은 진행(과목만 비움).
        String subjectLabel = null;
        if (lesson.getProblemId() != null) {
            subjectLabel = problemRepository.findById(lesson.getProblemId())
                    .map(p -> p.getSubject() == null ? null : p.getSubject().getDisplayName())
                    .orElse(null);
        }

        SettlementPolicy.Distribution dist = SettlementPolicy.distribute(coinCost);
        Settlement settlement = Settlement.builder()
                .tutorId(tutorId)
                .lessonId(request.getLessonId())
                .totalCoin(coinCost)
                .platformFeeCoin(dist.platformFeeCoin())
                .tutorCoin(dist.tutorCoin())
                .tutorAmount(dist.tutorAmount())
                .subject(subjectLabel)
                // 실제 수업 날짜(종료 시각, 없으면 시작 시각).
                .lessonDate(lesson.getEndedAt() != null ? lesson.getEndedAt() : lesson.getStartedAt())
                .build();

        // 2차 방어: 동시 호출로 위 체크를 둘 다 통과해도
        // lesson_id UNIQUE 제약이 중복 insert를 DB에서 막는다.
        try {
            settlementRepository.saveAndFlush(settlement);
        } catch (DataIntegrityViolationException e) {
            throw BusinessException.conflict("이미 정산된 강의입니다. lessonId: " + request.getLessonId(), e);
        }
        return SettlementResponse.from(settlement);
    }

    /**
     * 강사별 정산 내역 조회
     */
    public List<SettlementResponse> getByTutor(Long tutorId) {
        List<Settlement> all = settlementRepository.findByTutorIdOrderByCreatedAtDesc(tutorId);
        Set<Long> openReports = openReportLessonIds(all); // 신고 조회 1회(N+1 제거)
        // CALCULATED인데 신고 처리 중이면 reportPending=true → 프론트가 '신고 처리 중' 표시 + 출금 비활성
        return all.stream()
                .map(s -> SettlementResponse.from(s,
                        s.getStatus() == SettlementStatus.CALCULATED
                                && openReports.contains(s.getLessonId())))
                .toList();
    }

    /** 정산 보류 기간(수업 종료 후 이 시간 동안은 신고 대비로 정산을 미룬다). */
    private static final long SETTLEMENT_HOLD_HOURS = 24;

    /**
     * 정산 예정 목록 — 완료된 과금 강의 중 '아직 정산 레코드가 없는' 건.
     * 각 건의 보류 사유(24h 대기 / 신고 보류 / 처리 예정)와 예상 정산금을 함께 내려준다.
     * (24h 보류 구간엔 정산 레코드가 아직 없어 강사가 화면에서 확인할 방법이 없던 문제 해결)
     */
    public List<PendingSettlementResponse> getPendingByTutor(Long tutorId) {
        List<Lesson> completed = lessonRepository
                .findByTutorIdAndStatusAndCoinCostIsNotNull(tutorId, LessonStatus.COMPLETED);
        if (completed.isEmpty()) return List.of();

        // 이미 정산 레코드가 있는 강의는 제외.
        Set<Long> settledLessonIds = new HashSet<>();
        for (Settlement s : settlementRepository.findByTutorIdOrderByCreatedAtDesc(tutorId)) {
            settledLessonIds.add(s.getLessonId());
        }
        List<Lesson> pending = completed.stream()
                .filter(l -> !settledLessonIds.contains(l.getId()))
                .toList();
        if (pending.isEmpty()) return List.of();

        // 신고 보류 강의 집합(1회 조회) + 표시용 과목(문제별 1회 조회).
        List<Long> lessonIds = pending.stream().map(Lesson::getId).toList();
        Set<Long> reported = new HashSet<>(
                reportRepository.findLessonIdsWithStatusIn(lessonIds, OPEN_REPORTS));

        Map<Long, String> subjectByProblem = new HashMap<>();
        pending.stream()
                .map(Lesson::getProblemId)
                .filter(pid -> pid != null && !subjectByProblem.containsKey(pid))
                .distinct()
                .forEach(pid -> problemRepository.findById(pid).ifPresent(p ->
                        subjectByProblem.put(pid,
                                p.getSubject() == null ? null : p.getSubject().getDisplayName())));

        LocalDateTime cutoff = LocalDateTime.now().minusHours(SETTLEMENT_HOLD_HOURS);

        return pending.stream()
                .map(l -> {
                    PendingSettlementReason reason;
                    if (reported.contains(l.getId())) {
                        reason = PendingSettlementReason.REPORT_HOLD;
                    } else if (l.getEndedAt() != null && l.getEndedAt().isAfter(cutoff)) {
                        reason = PendingSettlementReason.WAITING_PERIOD;
                    } else {
                        reason = PendingSettlementReason.PROCESSING;
                    }
                    int expected = SettlementPolicy.distribute(l.getCoinCost()).tutorAmount();
                    String subject = l.getProblemId() == null
                            ? null : subjectByProblem.get(l.getProblemId());
                    return new PendingSettlementResponse(
                            l.getId(), l.getCoinCost(), expected, subject, l.getEndedAt(), reason);
                })
                // 최근 수업이 위로(종료 시각 내림차순, null은 뒤로).
                .sorted(Comparator.comparing(PendingSettlementResponse::lessonDate,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();
    }

    /**
     * 강사별 + 상태별 정산 내역
     */
    public List<SettlementResponse> getByTutorAndStatus(Long tutorId, SettlementStatus status) {
        return settlementRepository.findByTutorIdAndStatusOrderByCreatedAtDesc(tutorId, status)
                .stream()
                .map(SettlementResponse::from)
                .toList();
    }

    /**
     * 정산 상세 단건 조회
     */
    public SettlementResponse getDetail(Long settlementId, Long tutorId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> BusinessException.notFound("정산 정보를 찾을 수 없습니다."));
        // 본인 정산만 열람 가능(IDOR 방지)
        if (!settlement.getTutorId().equals(tutorId)) {
            throw BusinessException.forbidden("본인의 정산만 조회할 수 있습니다.");
        }
        return SettlementResponse.from(settlement);
    }

    /**
     * 강사별 정산 요약 (총 정산 금액, 송금 완료/대기 금액 등)
     */
    public SettlementSummaryResponse getSummary(Long tutorId) {
        SettlementRepository.SettlementAggregate agg = settlementRepository.aggregateByTutor(tutorId);
        return new SettlementSummaryResponse(
                tutorId,
                agg.getTotalAmount(),
                agg.getTransferredAmount(),
                agg.getPendingAmount(),
                agg.getSettlementCount()
        );
    }

    /**
     * 출금 요청 (강사 → 시스템)
     * CALCULATED → PENDING
     */
    @Transactional
    public SettlementResponse requestWithdraw(Long settlementId, Long tutorId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> BusinessException.notFound("정산 정보를 찾을 수 없습니다."));

        // 본인 확인
        if (!settlement.getTutorId().equals(tutorId)) {
            throw BusinessException.forbidden("본인의 정산만 출금 요청 가능합니다.");
        }

        // 정산 계좌 등록 필수
        requireSettlementAccount(tutorId);

        // 상태 체크
        if (settlement.getStatus() != SettlementStatus.CALCULATED) {
            throw BusinessException.conflict("출금 요청 가능한 상태가 아닙니다. 현재 상태: " + settlement.getStatus());
        }

        // 신고 보류 — 처리 중인 신고가 있으면 출금 막음(정산 생성 후 들어온 신고 케이스)
        if (hasOpenReport(settlement.getLessonId())) {
            throw BusinessException.conflict("신고 처리 중인 강의의 정산은 출금할 수 없어요. 처리 완료 후 가능합니다.");
        }

        settlement.markPending();
        return SettlementResponse.from(settlement);
    }

    /**
     * 일괄 출금 요청
     * CALCULATED 상태인 모든 정산을 한 번에 PENDING으로 변경
     *
     * 미래에 펌뱅킹 연동 시: 모든 정산 금액을 합산하여 한 번에 송금
     */
    @Transactional
    public BulkWithdrawResponse requestBulkWithdraw(Long tutorId) {
        List<Settlement> calculatedAll = settlementRepository
                .findByTutorIdAndStatusOrderByCreatedAtDesc(
                        tutorId, SettlementStatus.CALCULATED
                );

        // 신고 처리 중인 강의의 정산은 제외(출금 보류). 나머지만 일괄 출금. (신고 조회 1회)
        Set<Long> openReports = openReportLessonIds(calculatedAll);
        List<Settlement> calculated = calculatedAll.stream()
                .filter(s -> !openReports.contains(s.getLessonId()))
                .toList();

        if (calculated.isEmpty()) {
            throw BusinessException.badRequest(
                    calculatedAll.isEmpty()
                            ? "출금 가능한 정산이 없습니다."
                            : "출금 가능한 정산이 모두 신고 처리 중이라 출금할 수 없어요.");
        }

        // 정산 계좌 등록 필수
        requireSettlementAccount(tutorId);

        int totalAmount = calculated.stream()
                .mapToInt(Settlement::getTutorAmount)
                .sum();

        calculated.forEach(Settlement::markPending);

        return new BulkWithdrawResponse(
                calculated.size(),
                totalAmount,
                calculated.stream()
                        .map(SettlementResponse::from)
                        .toList()
        );
    }

    /**
     * 출금 완료 처리 (관리자/시스템)
     * PENDING → TRANSFERRED
     *
     * TODO: 실제 은행 송금 연동 시 여기에 로직 추가
     * 지금은 Mock 처리 (상태만 변경)
     */
    @Transactional
    public SettlementResponse completeWithdraw(Long settlementId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> BusinessException.notFound("정산 정보를 찾을 수 없습니다."));

        if (settlement.getStatus() != SettlementStatus.PENDING) {
            throw BusinessException.conflict("출금 대기 상태가 아닙니다. 현재 상태: " + settlement.getStatus());
        }

        // TODO: 실제 송금 호출 (은행 API 등)
        // try { bankService.transfer(...); } catch (...) { settlement.markFailed(); }

        settlement.markTransferred();
        return SettlementResponse.from(settlement);
    }

    /**
     * 출금 실패 처리
     */
    @Transactional
    public SettlementResponse failWithdraw(Long settlementId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> BusinessException.notFound("정산 정보를 찾을 수 없습니다."));

        // 송금 대기(PENDING)만 실패 처리 가능 — 이미 송금 완료된 건을 FAILED로 뒤집지 못하게.
        if (settlement.getStatus() != SettlementStatus.PENDING) {
            throw BusinessException.conflict("출금 대기 상태가 아닙니다. 현재 상태: " + settlement.getStatus());
        }
        settlement.markFailed();
        return SettlementResponse.from(settlement);
    }

    /**
     * 송금 실패분 재시도 (관리자) — FAILED → CALCULATED.
     * 실패한 정산을 다시 출금 요청 가능한 상태로 되돌린다(영구 정체 방지).
     */
    @Transactional
    public SettlementResponse retryWithdraw(Long settlementId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> BusinessException.notFound("정산 정보를 찾을 수 없습니다."));
        settlement.retryAfterFailure();
        return SettlementResponse.from(settlement);
    }

    /**
     * 정산 취소(롤백) — 강의 환불/취소 흐름에서 호출.
     * 해당 강의의 정산을 CANCELED로 무효화한다(요약 집계에서 제외됨).
     * 이미 송금 완료(TRANSFERRED)된 건은 엔티티 cancel()이 막는다.
     * 정산이 없으면(아직 미정산) 조용히 무시 — 환불은 정상 진행돼야 하므로.
     */
    @Transactional
    public void cancelByLesson(Long lessonId) {
        settlementRepository.findByLessonId(lessonId)
                .ifPresent(Settlement::cancel);
    }

    /** 정산 단건 취소(관리자/운영) */
    @Transactional
    public SettlementResponse cancelSettlement(Long settlementId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> BusinessException.notFound("정산 정보를 찾을 수 없습니다."));
        settlement.cancel();
        return SettlementResponse.from(settlement);
    }

    // ── 관리자 콘솔: 조회 ──

    /** 관리자 정산 목록 — status가 null이면 전체, 아니면 상태 필터(최신순). */
    public List<Settlement> getSettlementsForAdmin(SettlementStatus status) {
        return (status == null)
                ? settlementRepository.findAllByOrderByCreatedAtDesc()
                : settlementRepository.findByStatusOrderByCreatedAtDesc(status);
    }

    /** 관리자 정산 목록(페이지) — status가 null이면 전체, 아니면 상태 필터(최신순). */
    public org.springframework.data.domain.Page<Settlement> getSettlementsForAdmin(
            SettlementStatus status, org.springframework.data.domain.Pageable pageable) {
        return (status == null)
                ? settlementRepository.findAllByOrderByCreatedAtDesc(pageable)
                : settlementRepository.findByStatusOrderByCreatedAtDesc(status, pageable);
    }

    /** 관리자 정산 상세 — 엔티티 그대로(본인 검증 없이 운영자 전권 조회). */
    public Settlement getSettlementForAdmin(Long settlementId) {
        return settlementRepository.findById(settlementId)
                .orElseThrow(() -> BusinessException.notFound(
                        "정산 정보를 찾을 수 없습니다. settlementId: " + settlementId));
    }

    /** 상태별 합계/건수 집계 — 대시보드용. */
    public SettlementRepository.SettlementStatusAggregate aggregateByStatus(SettlementStatus status) {
        return settlementRepository.aggregateByStatus(status);
    }

    /** 출금 전 정산 계좌 등록 확인 */
    private void requireSettlementAccount(Long tutorId) {
        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));
        if (!tutor.hasSettlementAccount()) {
            throw BusinessException.badRequest("정산 계좌를 먼저 등록해 주세요. (마이페이지 > 정산 계좌 관리)");
        }
    }
}