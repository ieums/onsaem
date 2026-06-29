package com.ieum.backend.domain.settlement.controller;

import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.settlement.dto.request.CalculateSettlementRequest;
import com.ieum.backend.domain.settlement.dto.response.BulkWithdrawResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementSummaryResponse;
import com.ieum.backend.domain.settlement.entity.enums.SettlementStatus;
import com.ieum.backend.domain.settlement.service.SettlementService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/settlements")
@RequiredArgsConstructor
public class SettlementController {

    private final SettlementService settlementService;

    /**
     * 정산 계산 (강의 완료 시 호출)
     * 추후 강의 도메인이 완성되면 LectureService에서 자동 호출
     * 지금은 수동 호출 (테스트용)
     *
     * POST /api/v1/settlements/calculate
     */
    @PostMapping("/calculate")
    public ResponseEntity<SettlementResponse> calculate(
            @RequestBody @Valid CalculateSettlementRequest request) {
        return ResponseEntity.ok(settlementService.calculate(request));
    }

    /**
     * 강사별 정산 내역
     * GET /api/v1/settlements?tutorId=1&status=CALCULATED (status 선택)
     */
    @GetMapping
    public ResponseEntity<List<SettlementResponse>> getByTutor(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam(required = false) SettlementStatus status) {
        Long tutorId = principal.id();
        if (status != null) {
            return ResponseEntity.ok(settlementService.getByTutorAndStatus(tutorId, status));
        }
        return ResponseEntity.ok(settlementService.getByTutor(tutorId));
    }

    /**
     * 정산 상세
     * GET /api/v1/settlements/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<SettlementResponse> getDetail(
            @PathVariable Long id,
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(settlementService.getDetail(id, principal.id()));
    }

    /**
     * 강사 정산 요약 (총액, 송금 완료액, 대기액 등)
     * GET /api/v1/settlements/summary?tutorId=1
     */
    @GetMapping("/summary")
    public ResponseEntity<SettlementSummaryResponse> getSummary(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(settlementService.getSummary(principal.id()));
    }

    /**
     * 출금 요청 (강사 액션)
     * POST /api/v1/settlements/{id}/withdraw?tutorId=1
     */
    @PostMapping("/{id}/withdraw")
    public ResponseEntity<SettlementResponse> requestWithdraw(
            @PathVariable Long id,
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(settlementService.requestWithdraw(id, principal.id()));
    }

    /**
     * 일괄 출금 요청
     * POST /api/v1/settlements/withdraw-all?tutorId=1
     */
    @PostMapping("/withdraw-all")
    public ResponseEntity<BulkWithdrawResponse> requestBulkWithdraw(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(settlementService.requestBulkWithdraw(principal.id()));
    }

    /**
     * 출금 완료 처리 (관리자/시스템 액션)
     * POST /api/v1/settlements/{id}/complete
     *
     * TODO: 추후 관리자 권한 체크 추가
     */
    @PostMapping("/{id}/complete")
    public ResponseEntity<SettlementResponse> completeWithdraw(@PathVariable Long id) {
        return ResponseEntity.ok(settlementService.completeWithdraw(id));
    }

    /**
     * 출금 실패 처리 (관리자/시스템 액션)
     * POST /api/v1/settlements/{id}/fail
     */
    @PostMapping("/{id}/fail")
    public ResponseEntity<SettlementResponse> failWithdraw(@PathVariable Long id) {
        return ResponseEntity.ok(settlementService.failWithdraw(id));
    }

    /**
     * 정산 취소(롤백) — 강의 환불/취소 시.
     * 보통은 환불 플로우가 settlementService.cancelByLesson(lessonId)를 호출하지만,
     * 운영자가 정산 id로 직접 취소할 수 있도록 노출.
     * POST /api/v1/settlements/{id}/cancel
     *
     * TODO: 추후 관리자 권한 체크 추가
     */
    @PostMapping("/{id}/cancel")
    public ResponseEntity<SettlementResponse> cancelSettlement(@PathVariable Long id) {
        return ResponseEntity.ok(settlementService.cancelSettlement(id));
    }

    /**
     * 송금 실패분 재시도 (관리자) — FAILED → CALCULATED.
     * POST /api/v1/settlements/{id}/retry
     */
    @PostMapping("/{id}/retry")
    public ResponseEntity<SettlementResponse> retryWithdraw(@PathVariable Long id) {
        return ResponseEntity.ok(settlementService.retryWithdraw(id));
    }
}