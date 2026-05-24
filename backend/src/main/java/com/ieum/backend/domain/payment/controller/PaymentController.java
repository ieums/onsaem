package com.ieum.backend.domain.payment.controller;

import com.ieum.backend.domain.payment.dto.request.CoinChargeRequest;
import com.ieum.backend.domain.payment.dto.request.SubscribeRequest;
import com.ieum.backend.domain.payment.dto.response.*;
import com.ieum.backend.domain.payment.repository.CoinPackageRepository;
import com.ieum.backend.domain.payment.repository.SubscriptionPlanRepository;
import com.ieum.backend.domain.payment.service.CoinService;
import com.ieum.backend.domain.payment.service.PaymentService;
import com.ieum.backend.domain.payment.service.SubscriptionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final CoinService coinService;
    private final PaymentService paymentService;
    private final SubscriptionService subscriptionService;
    private final CoinPackageRepository coinPackageRepository;
    private final SubscriptionPlanRepository subscriptionPlanRepository;

    // ─── 코인 ─────────────────────────────────

    /**
     * 코인 잔액 조회
     * GET /api/v1/payments/coins/balance?studentId=1
     */
    @GetMapping("/coins/balance")
    public ResponseEntity<CoinBalanceResponse> getBalance(@RequestParam Long studentId) {
        return ResponseEntity.ok(coinService.getBalance(studentId));
    }

    /**
     * 코인 거래 내역
     * GET /api/v1/payments/coins/transactions?studentId=1
     */
    @GetMapping("/coins/transactions")
    public ResponseEntity<List<CoinTransactionResponse>> getTransactions(@RequestParam Long studentId) {
        return ResponseEntity.ok(coinService.getTransactions(studentId));
    }

    /**
     * 코인 패키지 목록 (판매 중인 것만)
     * GET /api/v1/payments/coins/packages
     */
    @GetMapping("/coins/packages")
    public ResponseEntity<List<CoinPackageResponse>> getCoinPackages() {
        List<CoinPackageResponse> packages = coinPackageRepository.findByActiveTrueOrderByPriceAsc()
                .stream()
                .map(CoinPackageResponse::from)
                .collect(Collectors.toList());
        return ResponseEntity.ok(packages);
    }

    // ─── 결제 ─────────────────────────────────

    /**
     * 결제 요청 생성 (포트원 결제창 호출 전)
     * POST /api/v1/payments/charge
     */
    @PostMapping("/charge")
    public ResponseEntity<PaymentResponse> createPayment(@RequestBody @Valid CoinChargeRequest request) {
        return ResponseEntity.ok(paymentService.createPayment(request));
    }

    /**
     * 결제 완료 확인 (포트원 웹훅 또는 클라이언트)
     * POST /api/v1/payments/confirm
     */
    @PostMapping("/confirm")
    public ResponseEntity<CoinBalanceResponse> confirmPayment(@RequestBody Map<String, String> body) {
        String merchantId = body.get("merchantId");
        String paymentId = body.get("portonePaymentId");
        String method = body.getOrDefault("method", "CARD");

        return ResponseEntity.ok(paymentService.completePayment(merchantId, paymentId, method));
    }

    /**
     * 결제 내역 조회
     * GET /api/v1/payments/history?studentId=1
     */
    @GetMapping("/history")
    public ResponseEntity<List<PaymentResponse>> getPaymentHistory(@RequestParam Long studentId) {
        return ResponseEntity.ok(paymentService.getPayments(studentId));
    }

    // ─── 구독 ─────────────────────────────────

    /**
     * 구독 플랜 목록
     * GET /api/v1/payments/subscriptions/plans
     */
    @GetMapping("/subscriptions/plans")
    public ResponseEntity<List<SubscriptionPlanResponse>> getSubscriptionPlans() {
        List<SubscriptionPlanResponse> plans = subscriptionPlanRepository.findByActiveTrueOrderByPriceAsc()
                .stream()
                .map(SubscriptionPlanResponse::from)
                .collect(Collectors.toList());
        return ResponseEntity.ok(plans);
    }

    /**
     * 구독 시작
     * POST /api/v1/payments/subscriptions
     */
    @PostMapping("/subscriptions")
    public ResponseEntity<SubscriptionResponse> subscribe(@RequestBody @Valid SubscribeRequest request) {
        return ResponseEntity.ok(subscriptionService.subscribe(request));
    }

    /**
     * 내 구독 조회
     * GET /api/v1/payments/subscriptions/me?studentId=1
     */
    @GetMapping("/subscriptions/me")
    public ResponseEntity<SubscriptionResponse> getMySubscription(@RequestParam Long studentId) {
        SubscriptionResponse response = subscriptionService.getMySubscription(studentId);
        if (response == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(response);
    }

    /**
     * 구독 취소
     * DELETE /api/v1/payments/subscriptions?studentId=1
     */
    @DeleteMapping("/subscriptions")
    public ResponseEntity<SubscriptionResponse> cancelSubscription(@RequestParam Long studentId) {
        return ResponseEntity.ok(subscriptionService.cancelSubscription(studentId));
    }
}