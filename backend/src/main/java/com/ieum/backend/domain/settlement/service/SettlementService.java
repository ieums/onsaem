package com.ieum.backend.domain.settlement.service;

import com.ieum.backend.domain.settlement.dto.request.CalculateSettlementRequest;
import com.ieum.backend.domain.settlement.dto.response.SettlementResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementSummaryResponse;
import com.ieum.backend.domain.settlement.entity.Settlement;
import com.ieum.backend.domain.payment.entity.enums.SettlementStatus;
import com.ieum.backend.domain.settlement.repository.SettlementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SettlementService {

    private final SettlementRepository settlementRepository;

    /**
     * 정산 계산 (강의 완료 시 호출)
     * 80%/20% 분배는 Settlement.builder()가 자동 처리
     */
    @Transactional
    public SettlementResponse calculate(CalculateSettlementRequest request) {
        // 중복 정산 방지
        settlementRepository.findByLessonId(request.getLessonId())
                .ifPresent(existing -> {
                    throw new RuntimeException(
                            "이미 정산된 강의입니다. settlementId: " + existing.getId()
                    );
                });

        Settlement settlement = Settlement.builder()
                .tutorId(request.getTutorId())
                .lessonId(request.getLessonId())
                .totalCoin(request.getTotalCoin())
                .build();

        settlementRepository.save(settlement);
        return SettlementResponse.from(settlement);
    }

    /**
     * 강사별 정산 내역 조회
     */
    public List<SettlementResponse> getByTutor(Long tutorId) {
        return settlementRepository.findByTutorIdOrderByCreatedAtDesc(tutorId)
                .stream()
                .map(SettlementResponse::from)
                .collect(Collectors.toList());
    }

    /**
     * 강사별 + 상태별 정산 내역
     */
    public List<SettlementResponse> getByTutorAndStatus(Long tutorId, SettlementStatus status) {
        return settlementRepository.findByTutorIdAndStatusOrderByCreatedAtDesc(tutorId, status)
                .stream()
                .map(SettlementResponse::from)
                .collect(Collectors.toList());
    }

    /**
     * 정산 상세 단건 조회
     */
    public SettlementResponse getDetail(Long settlementId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> new RuntimeException("정산 정보를 찾을 수 없습니다."));
        return SettlementResponse.from(settlement);
    }

    /**
     * 강사별 정산 요약 (총 정산 금액, 송금 완료/대기 금액 등)
     */
    public SettlementSummaryResponse getSummary(Long tutorId) {
        List<Settlement> all = settlementRepository.findByTutorIdOrderByCreatedAtDesc(tutorId);

        int totalAmount = all.stream()
                .mapToInt(Settlement::getTutorAmount)
                .sum();

        int transferredAmount = all.stream()
                .filter(s -> s.getStatus() == SettlementStatus.TRANSFERRED)
                .mapToInt(Settlement::getTutorAmount)
                .sum();

        int pendingAmount = all.stream()
                .filter(s -> s.getStatus() == SettlementStatus.CALCULATED
                        || s.getStatus() == SettlementStatus.PENDING)
                .mapToInt(Settlement::getTutorAmount)
                .sum();

        return new SettlementSummaryResponse(
                tutorId,
                totalAmount,
                transferredAmount,
                pendingAmount,
                all.size()
        );
    }

    /**
     * 출금 요청 (강사 → 시스템)
     * CALCULATED → PENDING
     */
    @Transactional
    public SettlementResponse requestWithdraw(Long settlementId, Long tutorId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> new RuntimeException("정산 정보를 찾을 수 없습니다."));

        // 본인 확인
        if (!settlement.getTutorId().equals(tutorId)) {
            throw new RuntimeException("본인의 정산만 출금 요청 가능합니다.");
        }

        // 상태 체크
        if (settlement.getStatus() != SettlementStatus.CALCULATED) {
            throw new RuntimeException(
                    "출금 요청 가능한 상태가 아닙니다. 현재 상태: " + settlement.getStatus()
            );
        }

        settlement.markPending();
        return SettlementResponse.from(settlement);
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
                .orElseThrow(() -> new RuntimeException("정산 정보를 찾을 수 없습니다."));

        if (settlement.getStatus() != SettlementStatus.PENDING) {
            throw new RuntimeException(
                    "출금 대기 상태가 아닙니다. 현재 상태: " + settlement.getStatus()
            );
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
                .orElseThrow(() -> new RuntimeException("정산 정보를 찾을 수 없습니다."));

        settlement.markFailed();
        return SettlementResponse.from(settlement);
    }
}