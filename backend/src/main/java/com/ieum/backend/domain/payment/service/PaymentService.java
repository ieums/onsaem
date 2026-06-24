package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.request.CoinChargeRequest;
import com.ieum.backend.domain.payment.dto.request.SubscribeChargeRequest;
import com.ieum.backend.domain.payment.dto.response.CoinBalanceResponse;
import com.ieum.backend.domain.payment.dto.response.PaymentResponse;
import com.ieum.backend.domain.payment.dto.response.SubscriptionResponse;
import com.ieum.backend.domain.payment.entity.CoinPackage;
import com.ieum.backend.domain.payment.entity.Payment;
import com.ieum.backend.domain.payment.entity.SubscriptionPlan;
import com.ieum.backend.domain.payment.entity.enums.PaymentTargetType;
import com.ieum.backend.domain.payment.repository.CoinPackageRepository;
import com.ieum.backend.domain.payment.repository.PaymentRepository;
import com.ieum.backend.domain.payment.repository.SubscriptionPlanRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
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
    private final PaymentCompletionTx completionTx;

    // ── 코인 결제 ──

    /**
     * 코인 결제 요청 생성 (포트원 결제창 호출 전)
     */
    @Transactional
    public PaymentResponse createCoinPayment(Long studentId, CoinChargeRequest request) {
        CoinPackage coinPackage = coinPackageRepository.findById(request.getCoinPackageId())
                .orElseThrow(() -> BusinessException.notFound("존재하지 않는 코인 패키지입니다."));

        String merchantId = "PAY-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Payment payment = Payment.builder()
                .merchantId(merchantId)
                .studentId(studentId)
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
     * 코인 결제 완료 처리.
     *
     * 포트원 검증(외부 HTTP)은 트랜잭션 밖(NOT_SUPPORTED)에서 수행하고,
     * 락·상태확정·적립만 짧은 트랜잭션(completionTx)으로 처리한다.
     * 검증 실패는 별도 트랜잭션으로 FAILED를 커밋해 메인 롤백에 휩쓸리지 않게 한다.
     */
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public CoinBalanceResponse completeCoinPayment(String merchantId, String paymentId, String method) {
        var ctx = completionTx.beginComplete(merchantId, PaymentTargetType.COIN_CHARGE);
        if (ctx.alreadyCompleted()) {                 // 멱등: 이미 완료된 결제
            return coinService.getBalance(ctx.studentId());
        }

        try {
            portOneClient.verifyPayment(paymentId, ctx.amount());
        } catch (Exception e) {
            completionTx.markFailed(merchantId);       // 별도 트랜잭션 → FAILED 보존
            throw e;
        }

        return completionTx.finalizeCoinCharge(merchantId, paymentId, method);
    }

    /**
     * 코인 결제 내역 조회
     */
    public List<PaymentResponse> getCoinPayments(Long studentId) {
        return paymentRepository.findByStudentIdAndTargetTypeOrderByCreatedAtDesc(
                        studentId, PaymentTargetType.COIN_CHARGE
                ).stream()
                .map(PaymentResponse::from)
                .toList();
    }

    /**
     * 코인 결제 상세 단건 조회
     */
    public PaymentResponse getCoinPaymentDetail(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> BusinessException.notFound("결제 정보를 찾을 수 없습니다."));

        if (payment.getTargetType() != PaymentTargetType.COIN_CHARGE) {
            throw BusinessException.badRequest("코인 충전 결제가 아닙니다.");
        }
        return PaymentResponse.from(payment);
    }

    /**
     * 코인 환불.
     *
     * 순서: (1) 검증 (2) 포트원 취소[외부, 트랜잭션 밖] (3) 코인 차감 + REFUNDED 확정[트랜잭션].
     * 포트원 취소를 먼저 해 사용자에게 돈을 돌려준 뒤 코인을 차감한다.
     * (3)이 실패하면 "포트원은 취소됐으나 코인 미차감" 불일치 → 로그로 수동 보정 대상 표시.
     */
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public CoinBalanceResponse refundCoinPayment(Long paymentId, String reason) {
        String portonePaymentId = completionTx.beginRefund(paymentId);

        portOneClient.cancelPayment(portonePaymentId, reason != null ? reason : "사용자 요청");

        try {
            return completionTx.finalizeRefund(paymentId);
        } catch (Exception e) {
            log.error("[환불 보상필요] 포트원 취소는 완료됐으나 코인 차감/상태변경 실패. paymentId={}", paymentId, e);
            throw e;
        }
    }

    // ── 구독 결제 ──

    /**
     * 구독 결제 요청 생성 (포트원 결제창 호출 전)
     */
    @Transactional
    public PaymentResponse createSubscriptionPayment(Long studentId, SubscribeChargeRequest request) {
        SubscriptionPlan plan = subscriptionPlanRepository.findById(request.getSubscriptionPlanId())
                .orElseThrow(() -> BusinessException.notFound("존재하지 않는 구독 플랜입니다."));

        // 이미 활성 구독이 있는지 체크
        subscriptionService.checkNoActiveSubscription(studentId);

        String merchantId = "SUB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Payment payment = Payment.builder()
                .merchantId(merchantId)
                .studentId(studentId)
                .amount(plan.getPrice())
                .productName(plan.getName() + " 구독")
                .targetType(PaymentTargetType.SUBSCRIPTION)
                .subscriptionPlan(plan)
                .build();

        paymentRepository.save(payment);
        return PaymentResponse.from(payment);
    }

    /**
     * 구독 결제 완료 처리 (포트원 검증 + 구독 활성화).
     * 코인 완료와 동일하게 외부 검증은 트랜잭션 밖, 확정/활성화는 짧은 트랜잭션.
     */
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public SubscriptionResponse completeSubscriptionPayment(
            String merchantId, String paymentId, String method, boolean autoRenew) {
        var ctx = completionTx.beginComplete(merchantId, PaymentTargetType.SUBSCRIPTION);
        if (ctx.alreadyCompleted()) {                 // 멱등: 이미 완료된 결제 → 기존 구독
            SubscriptionResponse existing = subscriptionService.getMySubscription(ctx.studentId());
            if (existing == null) {
                throw BusinessException.internalError("완료된 결제이나 활성 구독을 찾을 수 없습니다.");
            }
            return existing;
        }

        try {
            portOneClient.verifyPayment(paymentId, ctx.amount());
        } catch (Exception e) {
            completionTx.markFailed(merchantId);
            throw e;
        }

        return completionTx.finalizeSubscription(merchantId, paymentId, method, autoRenew);
    }

    /**
     * 구독 결제 내역 조회
     */
    public List<PaymentResponse> getSubscriptionPayments(Long studentId) {
        return paymentRepository.findByStudentIdAndTargetTypeOrderByCreatedAtDesc(
                        studentId, PaymentTargetType.SUBSCRIPTION
                ).stream()
                .map(PaymentResponse::from)
                .toList();
    }

    /**
     * 구독 결제 상세 단건 조회
     */
    public PaymentResponse getSubscriptionPaymentDetail(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> BusinessException.notFound("결제 정보를 찾을 수 없습니다."));

        if (payment.getTargetType() != PaymentTargetType.SUBSCRIPTION) {
            throw BusinessException.badRequest("구독 결제가 아닙니다.");
        }
        return PaymentResponse.from(payment);
    }

    // ── 공통 ──

    /**
     * 결제 실패 처리
     */
    @Transactional
    public void failPayment(String merchantId) {
        Payment payment = paymentRepository.findByMerchantId(merchantId)
                .orElseThrow(() -> BusinessException.notFound("결제 정보를 찾을 수 없습니다."));
        payment.fail();
    }
}