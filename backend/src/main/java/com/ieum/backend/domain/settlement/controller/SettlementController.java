package com.ieum.backend.domain.settlement.controller;

import com.ieum.backend.domain.settlement.dto.request.CalculateSettlementRequest;
import com.ieum.backend.domain.settlement.dto.response.BulkWithdrawResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementResponse;
import com.ieum.backend.domain.settlement.dto.response.SettlementSummaryResponse;
import com.ieum.backend.domain.settlement.entity.enums.SettlementStatus;
import com.ieum.backend.domain.settlement.service.SettlementService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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
            @RequestParam Long tutorId,
            @RequestParam(required = false) SettlementStatus status) {
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
    public ResponseEntity<SettlementResponse> getDetail(@PathVariable Long id) {
        return ResponseEntity.ok(settlementService.getDetail(id));
    }

    /**
     * 강사 정산 요약 (총액, 송금 완료액, 대기액 등)
     * GET /api/v1/settlements/summary?tutorId=1
     */
    @GetMapping("/summary")
    public ResponseEntity<SettlementSummaryResponse> getSummary(@RequestParam Long tutorId) {
        return ResponseEntity.ok(settlementService.getSummary(tutorId));
    }

    /**
     * 출금 요청 (강사 액션)
     * POST /api/v1/settlements/{id}/withdraw?tutorId=1
     */
    @PostMapping("/{id}/withdraw")
    public ResponseEntity<SettlementResponse> requestWithdraw(
            @PathVariable Long id,
            @RequestParam Long tutorId) {
        return ResponseEntity.ok(settlementService.requestWithdraw(id, tutorId));
    }

    /**
     * 일괄 출금 요청
     * POST /api/v1/settlements/withdraw-all?tutorId=1
     */
    @PostMapping("/withdraw-all")
    public ResponseEntity<BulkWithdrawResponse> requestBulkWithdraw(
            @RequestParam Long tutorId) {
        return ResponseEntity.ok(settlementService.requestBulkWithdraw(tutorId));
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
}