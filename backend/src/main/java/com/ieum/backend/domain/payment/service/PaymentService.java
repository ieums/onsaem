package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.request.CoinChargeRequest;
import com.ieum.backend.domain.payment.dto.request.SubscribeChargeRequest;
import com.ieum.backend.domain.payment.dto.response.CoinBalanceResponse;
import com.ieum.backend.domain.payment.dto.response.PaymentResponse;
import com.ieum.backend.domain.payment.dto.response.SubscriptionResponse;
import com.ieum.backend.domain.payment.entity.CoinPackage;
import com.ieum.backend.domain.payment.entity.Payment;
import com.ieum.backend.domain.payment.entity.SubscriptionPlan;
import com.ieum.backend.domain.payment.entity.enums.PaymentMethod;
import com.ieum.backend.domain.payment.entity.enums.PaymentStatus;
import com.ieum.backend.domain.payment.entity.enums.PaymentTargetType;
import com.ieum.backend.domain.payment.repository.CoinPackageRepository;
import com.ieum.backend.domain.payment.repository.PaymentRepository;
import com.ieum.backend.domain.payment.repository.SubscriptionPlanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final CoinPackageRepository coinPackageRepository;
    private final SubscriptionPlanRepository subscriptionPlanRepository;

    private final CoinService coinService;
    private final SubscriptionService subscriptionService;
    private final PortOneClient portOneClient;

    // ═══════════════════════════════════════════════
    //  코인 결제
    // ═══════════════════════════════════════════════

    /**
     * 코인 결제 요청 생성 (포트원 결제창 호출 전)
     */
    @Transactional
    public PaymentResponse createCoinPayment(CoinChargeRequest request) {
        CoinPackage coinPackage = coinPackageRepository.findById(request.getCoinPackageId())
                .orElseThrow(() -> new RuntimeException("존재하지 않는 코인 패키지입니다."));

        String merchantId = "PAY-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Payment payment = Payment.builder()
                .merchantId(merchantId)
                .studentId(request.getStudentId())
                .amount(coinPackage.getPrice())
                .coinAmount(coinPackage.getCoinAmount())
                .bonusCoinAmount(coinPackage.getBonusAmount())
                .productName(coinPackage.getName() + " 충전")
                .targetType(PaymentTargetType.COIN_CHARGE)
                .build();

        paymentRepository.save(payment);
        return PaymentResponse.from(payment);
    }

    /**
     * 코인 결제 완료 처리
     */
    @Transactional
    public CoinBalanceResponse completeCoinPayment(String merchantId, String paymentId, String method) {
        Payment payment = paymentRepository.findByMerchantId(merchantId)
                .orElseThrow(() -> new RuntimeException("결제 정보를 찾을 수 없습니다."));

        // 코인 결제인지 검증
        if (payment.getTargetType() != PaymentTargetType.COIN_CHARGE) {
            throw new RuntimeException("코인 충전 결제가 아닙니다.");
        }

        try {
            portOneClient.verifyPayment(paymentId, payment.getAmount());
        } catch (Exception e) {
            payment.fail();
            paymentRepository.save(payment);
            throw e;
        }

        PaymentMethod paymentMethod = PaymentMethod.fromString(method);
        payment.complete(paymentId, paymentMethod);

        return coinService.charge(
                payment.getStudentId(),
                payment.getCoinAmount(),
                payment.getBonusCoinAmount(),
                payment.getId()
        );
    }

    /**
     * 코인 결제 내역 조회
     */
    public List<PaymentResponse> getCoinPayments(Long studentId) {
        return paymentRepository.findByStudentIdAndTargetTypeOrderByCreatedAtDesc(
                        studentId, PaymentTargetType.COIN_CHARGE
                ).stream()
                .map(PaymentResponse::from)
                .collect(Collectors.toList());
    }

    /**
     * 코인 결제 상세 단건 조회
     */
    public PaymentResponse getCoinPaymentDetail(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("결제 정보를 찾을 수 없습니다."));

        if (payment.getTargetType() != PaymentTargetType.COIN_CHARGE) {
            throw new RuntimeException("코인 충전 결제가 아닙니다.");
        }
        return PaymentResponse.from(payment);
    }

    /**
     * 코인 환불
     * - 환불 가능 조건 체크
     * - 포트원 결제 취소
     * - 코인 차감 + REFUND 트랜잭션 기록
     * - Payment 상태 REFUNDED로 변경
     */
    @Transactional
    public CoinBalanceResponse refundCoinPayment(Long paymentId, String reason) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("결제 정보를 찾을 수 없습니다."));

        // 1. 환불 가능 조건 체크
        if (payment.getStatus() != PaymentStatus.COMPLETED) {
            throw new RuntimeException("완료된 결제만 환불 가능합니다. 현재 상태: " + payment.getStatus());
        }
        if (payment.getTargetType() != PaymentTargetType.COIN_CHARGE) {
            throw new RuntimeException("코인 충전 결제만 환불 가능합니다.");
        }
        if (payment.getCompletedAt().isBefore(LocalDateTime.now().minusDays(7))) {
            throw new RuntimeException("결제 후 7일이 지나 환불할 수 없습니다.");
        }

        // 2. 포트원 결제 취소
        portOneClient.cancelPayment(
                payment.getPortonePaymentId(),
                reason != null ? reason : "사용자 요청"
        );

        // 3. 코인 차감 + 환불 트랜잭션 기록
        int totalCoinToRefund = payment.getCoinAmount() +
                (payment.getBonusCoinAmount() != null ? payment.getBonusCoinAmount() : 0);
        CoinBalanceResponse balance = coinService.refund(
                payment.getStudentId(),
                totalCoinToRefund,
                payment.getId()
        );

        // 4. Payment 상태 변경
        payment.refund();

        return balance;
    }

    // ═══════════════════════════════════════════════
    //  구독 결제
    // ═══════════════════════════════════════════════

    /**
     * 구독 결제 요청 생성 (포트원 결제창 호출 전)
     */
    @Transactional
    public PaymentResponse createSubscriptionPayment(SubscribeChargeRequest request) {
        SubscriptionPlan plan = subscriptionPlanRepository.findById(request.getSubscriptionPlanId())
                .orElseThrow(() -> new RuntimeException("존재하지 않는 구독 플랜입니다."));

        // 이미 활성 구독이 있는지 체크
        subscriptionService.checkNoActiveSubscription(request.getStudentId());

        String merchantId = "SUB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Payment payment = Payment.builder()
                .merchantId(merchantId)
                .studentId(request.getStudentId())
                .amount(plan.getPrice())
                .productName(plan.getName() + " 구독")
                .targetType(PaymentTargetType.SUBSCRIPTION)
                .subscriptionPlan(plan)
                .build();

        paymentRepository.save(payment);
        return PaymentResponse.from(payment);
    }

    /**
     * 구독 결제 완료 처리 (포트원 검증 + 구독 활성화)
     */
    @Transactional
    public SubscriptionResponse completeSubscriptionPayment(
            String merchantId, String paymentId, String method, boolean autoRenew) {
        Payment payment = paymentRepository.findByMerchantId(merchantId)
                .orElseThrow(() -> new RuntimeException("결제 정보를 찾을 수 없습니다."));

        // 구독 결제인지 검증
        if (payment.getTargetType() != PaymentTargetType.SUBSCRIPTION) {
            throw new RuntimeException("구독 결제가 아닙니다.");
        }

        try {
            portOneClient.verifyPayment(paymentId, payment.getAmount());
        } catch (Exception e) {
            payment.fail();
            paymentRepository.save(payment);
            throw e;
        }

        PaymentMethod paymentMethod = PaymentMethod.fromString(method);
        payment.complete(paymentId, paymentMethod);

        // 구독 활성화
        return subscriptionService.activateAfterPayment(
                payment.getStudentId(),
                payment.getSubscriptionPlan().getId(),
                payment.getAmount(),
                autoRenew,
                payment.getId()
        );
    }

    /**
     * 구독 결제 내역 조회
     */
    public List<PaymentResponse> getSubscriptionPayments(Long studentId) {
        return paymentRepository.findByStudentIdAndTargetTypeOrderByCreatedAtDesc(
                        studentId, PaymentTargetType.SUBSCRIPTION
                ).stream()
                .map(PaymentResponse::from)
                .collect(Collectors.toList());
    }

    /**
     * 구독 결제 상세 단건 조회
     */
    public PaymentResponse getSubscriptionPaymentDetail(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("결제 정보를 찾을 수 없습니다."));

        if (payment.getTargetType() != PaymentTargetType.SUBSCRIPTION) {
            throw new RuntimeException("구독 결제가 아닙니다.");
        }
        return PaymentResponse.from(payment);
    }

    // ═══════════════════════════════════════════════
    //  공통
    // ═══════════════════════════════════════════════

    /**
     * 결제 실패 처리
     */
    @Transactional
    public void failPayment(String merchantId) {
        Payment payment = paymentRepository.findByMerchantId(merchantId)
                .orElseThrow(() -> new RuntimeException("결제 정보를 찾을 수 없습니다."));
        payment.fail();
    }
}