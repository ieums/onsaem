package com.ieum.backend.domain.payment.controller;

import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.payment.dto.request.*;
import com.ieum.backend.domain.payment.dto.response.*;
import com.ieum.backend.domain.payment.repository.CoinPackageRepository;
import com.ieum.backend.domain.payment.repository.SubscriptionPlanRepository;
import com.ieum.backend.domain.payment.service.CoinService;
import com.ieum.backend.domain.payment.service.PaymentService;
import com.ieum.backend.domain.payment.service.SubscriptionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final CoinService coinService;
    private final PaymentService paymentService;
    private final SubscriptionService subscriptionService;
    private final CoinPackageRepository coinPackageRepository;
    private final SubscriptionPlanRepository subscriptionPlanRepository;

    // ── 코인 — 잔액 · 거래내역 · 패키지 ──

    /**
     * 코인 잔액 조회
     * GET /api/v1/payments/coins/balance?studentId=1
     */
    @GetMapping("/coins/balance")
    public ResponseEntity<CoinBalanceResponse> getCoinBalance(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(coinService.getBalance(principal.id()));
    }

    /**
     * 코인 거래 내역 조회 (충전/사용/환불 모두 포함)
     * GET /api/v1/payments/coins/transactions?studentId=1
     */
    @GetMapping("/coins/transactions")
    public ResponseEntity<List<CoinTransactionResponse>> getCoinTransactions(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(coinService.getTransactions(principal.id()));
    }

    /**
     * 코인 패키지 목록 (판매 중)
     * GET /api/v1/payments/coins/packages
     */
    @GetMapping("/coins/packages")
    public ResponseEntity<List<CoinPackageResponse>> getCoinPackages() {
        List<CoinPackageResponse> packages = coinPackageRepository.findByActiveTrueOrderByPriceAsc()
                .stream()
                .map(CoinPackageResponse::from)
                .toList();
        return ResponseEntity.ok(packages);
    }

    // ── 코인 — 결제 (충전) ──

    /**
     * 코인 충전 결제 요청 생성 (포트원 결제창 호출 전)
     * POST /api/v1/payments/coins/charge
     */
    @PostMapping("/coins/charge")
    public ResponseEntity<PaymentResponse> createCoinPayment(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestBody @Valid CoinChargeRequest request) {
        return ResponseEntity.ok(paymentService.createCoinPayment(principal.id(), request));
    }

    /**
     * 코인 충전 결제 완료 확인 (포트원 검증 + 코인 충전)
     * POST /api/v1/payments/coins/confirm
     */
    @PostMapping("/coins/confirm")
    public ResponseEntity<CoinBalanceResponse> completeCoinPayment(
            @RequestBody @Valid CoinConfirmRequest request) {
        String method = request.getMethod() != null ? request.getMethod() : "CARD";
        return ResponseEntity.ok(paymentService.completeCoinPayment(
                request.getMerchantId(),
                request.getPortonePaymentId(),
                method
        ));
    }

    /**
     * 코인 충전 내역 (Payment 리스트)
     * GET /api/v1/payments/coins/payments?studentId=1
     */
    @GetMapping("/coins/payments")
    public ResponseEntity<List<PaymentResponse>> getCoinPayments(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(paymentService.getCoinPayments(principal.id()));
    }

    /**
     * 코인 충전 상세 단건
     * GET /api/v1/payments/coins/payments/{id}
     */
    @GetMapping("/coins/payments/{id}")
    public ResponseEntity<PaymentResponse> getCoinPaymentDetail(@PathVariable Long id) {
        return ResponseEntity.ok(paymentService.getCoinPaymentDetail(id));
    }

    /**
     * 코인 충전 환불
     * POST /api/v1/payments/coins/payments/{id}/refund
     * Body: { "reason": "단순 변심" } (선택)
     */
    @PostMapping("/coins/payments/{id}/refund")
    public ResponseEntity<CoinBalanceResponse> refundCoinPayment(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        String reason = body != null ? body.get("reason") : null;
        return ResponseEntity.ok(paymentService.refundCoinPayment(id, reason));
    }

    // ── 구독 — 플랜 · 내 구독 ──

    /**
     * 구독 플랜 목록
     * GET /api/v1/payments/subscriptions/plans
     */
    @GetMapping("/subscriptions/plans")
    public ResponseEntity<List<SubscriptionPlanResponse>> getSubscriptionPlans() {
        List<SubscriptionPlanResponse> plans = subscriptionPlanRepository.findByActiveTrueOrderByPriceAsc()
                .stream()
                .map(SubscriptionPlanResponse::from)
                .toList();
        return ResponseEntity.ok(plans);
    }

    /**
     * 내 활성 구독 조회
     * GET /api/v1/payments/subscriptions/me?studentId=1
     */
    @GetMapping("/subscriptions/me")
    public ResponseEntity<SubscriptionResponse> getMySubscription(
            @AuthenticationPrincipal AuthPrincipal principal) {
        SubscriptionResponse response = subscriptionService.getMySubscription(principal.id());
        if (response == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(response);
    }

    /**
     * 구독 취소 (자동갱신 OFF, 만료일까지 유지)
     * DELETE /api/v1/payments/subscriptions?studentId=1
     */
    @DeleteMapping("/subscriptions")
    public ResponseEntity<SubscriptionResponse> cancelSubscription(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(subscriptionService.cancelSubscription(principal.id()));
    }

    /**
     * 자동갱신 ON/OFF 토글
     * PATCH /api/v1/payments/subscriptions/auto-renew
     */
    @PatchMapping("/subscriptions/auto-renew")
    public ResponseEntity<SubscriptionResponse> toggleAutoRenew(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestBody @Valid AutoRenewRequest request) {
        return ResponseEntity.ok(
                subscriptionService.toggleAutoRenew(principal.id(), request.getAutoRenew())
        );
    }

    // ── 구독 — 결제 ──

    /**
     * 구독 결제 요청 생성 (포트원 결제창 호출 전)
     * POST /api/v1/payments/subscriptions/charge
     */
    @PostMapping("/subscriptions/charge")
    public ResponseEntity<PaymentResponse> createSubscriptionPayment(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestBody @Valid SubscribeChargeRequest request) {
        return ResponseEntity.ok(paymentService.createSubscriptionPayment(principal.id(), request));
    }

    /**
     * 구독 결제 완료 확인 (포트원 검증 + 구독 활성화)
     * POST /api/v1/payments/subscriptions/confirm
     */
    @PostMapping("/subscriptions/confirm")
    public ResponseEntity<SubscriptionResponse> completeSubscriptionPayment(
            @RequestBody @Valid SubscriptionConfirmRequest request) {
        return ResponseEntity.ok(paymentService.completeSubscriptionPayment(
                request.getMerchantId(),
                request.getPortonePaymentId(),
                request.getMethod(),
                request.getAutoRenew() != null ? request.getAutoRenew() : false
        ));
    }

    /**
     * 구독 결제 내역 (Payment 리스트)
     * GET /api/v1/payments/subscriptions/payments?studentId=1
     */
    @GetMapping("/subscriptions/payments")
    public ResponseEntity<List<PaymentResponse>> getSubscriptionPayments(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(paymentService.getSubscriptionPayments(principal.id()));
    }

    /**
     * 구독 결제 상세 단건
     * GET /api/v1/payments/subscriptions/payments/{id}
     */
    @GetMapping("/subscriptions/payments/{id}")
    public ResponseEntity<PaymentResponse> getSubscriptionPaymentDetail(@PathVariable Long id) {
        return ResponseEntity.ok(paymentService.getSubscriptionPaymentDetail(id));
    }
}