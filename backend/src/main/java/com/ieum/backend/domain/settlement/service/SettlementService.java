package com.ieum.backend.domain.settlement.service;

import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.settlement.dto.request.CalculateSettlementRequest;
import com.ieum.backend.domain.settlement.dto.response.BulkWithdrawResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementSummaryResponse;
import com.ieum.backend.domain.settlement.entity.Settlement;
import com.ieum.backend.domain.settlement.entity.enums.SettlementStatus;
import com.ieum.backend.domain.settlement.policy.SettlementPolicy;
import com.ieum.backend.domain.settlement.repository.SettlementRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SettlementService {

    private final SettlementRepository settlementRepository;
    private final LessonRepository lessonRepository;   // 정산 대상 강사를 강의에서 권위있게 가져오기 위함
    private final TutorRepository tutorRepository;      // 출금 전 정산 계좌 등록 확인용

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

        SettlementPolicy.Distribution dist = SettlementPolicy.distribute(request.getTotalCoin());
        Settlement settlement = Settlement.builder()
                .tutorId(tutorId)
                .lessonId(request.getLessonId())
                .totalCoin(request.getTotalCoin())
                .platformFeeCoin(dist.platformFeeCoin())
                .tutorCoin(dist.tutorCoin())
                .tutorAmount(dist.tutorAmount())
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
        return settlementRepository.findByTutorIdOrderByCreatedAtDesc(tutorId)
                .stream()
                .map(SettlementResponse::from)
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
    public SettlementResponse getDetail(Long settlementId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> BusinessException.notFound("정산 정보를 찾을 수 없습니다."));
        return SettlementResponse.from(settlement);
    }

    /**
     * 강사별 정산 요약 (총 정산 금액, 송금 완료/대기 금액 등)
     */
    public SettlementSummaryResponse getSummary(Long tutorId) {
        SettlementRepository.SettlementAggregate agg = settlementRepository.aggregateByTutor(tutorId);
        return new SettlementSummaryResponse(
                tutorId,
                agg.getTotalAmount().intValue(),
                agg.getTransferredAmount().intValue(),
                agg.getPendingAmount().intValue(),
                agg.getSettlementCount().intValue()
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
        List<Settlement> calculated = settlementRepository
                .findByTutorIdAndStatusOrderByCreatedAtDesc(
                        tutorId, SettlementStatus.CALCULATED
                );

        if (calculated.isEmpty()) {
            throw BusinessException.badRequest("출금 가능한 정산이 없습니다.");
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

        settlement.markFailed();
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

    /** 출금 전 정산 계좌 등록 확인 */
    private void requireSettlementAccount(Long tutorId) {
        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));
        if (!tutor.hasSettlementAccount()) {
            throw BusinessException.badRequest("정산 계좌를 먼저 등록해 주세요. (마이페이지 > 정산 계좌 관리)");
        }
    }
}