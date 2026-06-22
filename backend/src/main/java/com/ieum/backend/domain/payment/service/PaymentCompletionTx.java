package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.response.CoinBalanceResponse;
import com.ieum.backend.domain.payment.dto.response.SubscriptionResponse;
import com.ieum.backend.domain.payment.entity.Payment;
import com.ieum.backend.domain.payment.entity.enums.PaymentMethod;
import com.ieum.backend.domain.payment.entity.enums.PaymentStatus;
import com.ieum.backend.domain.payment.entity.enums.PaymentTargetType;
import com.ieum.backend.domain.payment.policy.PaymentPolicy;
import com.ieum.backend.domain.payment.repository.PaymentRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 결제 완료/환불의 "DB 트랜잭션 단계"만 담당하는 빈.
 *
 * 포트원 외부 호출은 PaymentService(트랜잭션 밖)에서 수행하고,
 * 여기의 메서드들은 각각 독립된 짧은 트랜잭션으로 락·상태확정만 처리한다.
 * (별도 빈으로 분리해야 @Transactional 프록시가 적용된다 — 자기호출이면 무시됨)
 */
@Component
@RequiredArgsConstructor
public class PaymentCompletionTx {

    private final PaymentRepository paymentRepository;
    private final CoinService coinService;
    private final SubscriptionService subscriptionService;

    /** 완료 처리에 필요한 최소 스냅샷 (트랜잭션 종료 후 사용) */
    public record CompletionContext(boolean alreadyCompleted, Long studentId, int amount) {
        static CompletionContext alreadyCompleted(Long studentId) {
            return new CompletionContext(true, studentId, 0);
        }
        static CompletionContext pending(Long studentId, int amount) {
            return new CompletionContext(false, studentId, amount);
        }
    }

    /**
     * 완료 전 검증: 락 + 타입/상태 확인 후 검증에 쓸 금액·학생 스냅샷 반환.
     * 이미 COMPLETED면 alreadyCompleted=true로 돌려 호출부가 멱등 반환하게 한다.
     */
    @Transactional
    public CompletionContext beginComplete(String merchantId, PaymentTargetType type) {
        Payment payment = paymentRepository.findByMerchantIdForUpdate(merchantId)
                .orElseThrow(() -> BusinessException.notFound("결제 정보를 찾을 수 없습니다."));

        if (payment.getTargetType() != type) {
            throw BusinessException.badRequest("결제 종류가 일치하지 않습니다.");
        }
        if (payment.getStatus() == PaymentStatus.COMPLETED) {
            return CompletionContext.alreadyCompleted(payment.getStudentId());
        }
        if (payment.getStatus() != PaymentStatus.PENDING) {
            throw BusinessException.conflict("완료 처리할 수 없는 결제 상태입니다: " + payment.getStatus());
        }
        return CompletionContext.pending(payment.getStudentId(), payment.getAmount());
    }

    /**
     * 외부 검증 실패 시 별도 트랜잭션으로 실패 확정.
     * REQUIRES_NEW라 호출부의 예외 전파(롤백)와 무관하게 FAILED 상태가 커밋된다.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void markFailed(String merchantId) {
        paymentRepository.findByMerchantIdForUpdate(merchantId)
                .ifPresent(Payment::fail);
    }

    /** 코인 결제 확정 + 적립 (락 재확인, 동시 요청 멱등) */
    @Transactional
    public CoinBalanceResponse finalizeCoinCharge(String merchantId, String portonePaymentId, String method) {
        Payment payment = paymentRepository.findByMerchantIdForUpdate(merchantId)
                .orElseThrow(() -> BusinessException.notFound("결제 정보를 찾을 수 없습니다."));

        if (payment.getStatus() == PaymentStatus.COMPLETED) {
            return coinService.getBalance(payment.getStudentId());
        }
        if (payment.getStatus() != PaymentStatus.PENDING) {
            throw BusinessException.conflict("완료 처리할 수 없는 결제 상태입니다: " + payment.getStatus());
        }

        payment.complete(portonePaymentId, PaymentMethod.fromString(method));
        return coinService.charge(
                payment.getStudentId(),
                payment.getCoinAmount(),
                payment.getBonusCoinAmount(),
                payment.getId());
    }

    /** 구독 결제 확정 + 활성화 (락 재확인, 동시 요청 멱등) */
    @Transactional
    public SubscriptionResponse finalizeSubscription(
            String merchantId, String portonePaymentId, String method, boolean autoRenew) {
        Payment payment = paymentRepository.findByMerchantIdForUpdate(merchantId)
                .orElseThrow(() -> BusinessException.notFound("결제 정보를 찾을 수 없습니다."));

        if (payment.getStatus() == PaymentStatus.COMPLETED) {
            SubscriptionResponse existing = subscriptionService.getMySubscription(payment.getStudentId());
            if (existing == null) {
                throw BusinessException.internalError("완료된 결제이나 활성 구독을 찾을 수 없습니다.");
            }
            return existing;
        }
        if (payment.getStatus() != PaymentStatus.PENDING) {
            throw BusinessException.conflict("완료 처리할 수 없는 결제 상태입니다: " + payment.getStatus());
        }

        payment.complete(portonePaymentId, PaymentMethod.fromString(method));
        return subscriptionService.activateAfterPayment(
                payment.getStudentId(),
                payment.getSubscriptionPlan().getId(),
                payment.getAmount(),
                autoRenew,
                payment.getId());
    }

    /**
     * 환불 전 검증 + 포트원 취소에 쓸 결제ID 반환 (상태 변경 없음).
     */
    @Transactional(readOnly = true)
    public String beginRefund(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> BusinessException.notFound("결제 정보를 찾을 수 없습니다."));

        if (payment.getStatus() != PaymentStatus.COMPLETED) {
            throw BusinessException.badRequest("완료된 결제만 환불 가능합니다. 현재 상태: " + payment.getStatus());
        }
        if (payment.getTargetType() != PaymentTargetType.COIN_CHARGE) {
            throw BusinessException.badRequest("코인 충전 결제만 환불 가능합니다.");
        }
        if (payment.getCompletedAt().isBefore(LocalDateTime.now().minusDays(PaymentPolicy.REFUND_WINDOW_DAYS))) {
            throw BusinessException.badRequest(
                    "결제 후 " + PaymentPolicy.REFUND_WINDOW_DAYS + "일이 지나 환불할 수 없습니다.");
        }
        return payment.getPortonePaymentId();
    }

    /**
     * 코인 차감 + 상태 REFUNDED 확정 (포트원 취소 성공 후 호출).
     * 락 재확인으로 동시/중복 환불 방어. 이미 REFUNDED면 멱등 반환.
     */
    @Transactional
    public CoinBalanceResponse finalizeRefund(Long paymentId) {
        Payment payment = paymentRepository.findByIdForUpdate(paymentId)
                .orElseThrow(() -> BusinessException.notFound("결제 정보를 찾을 수 없습니다."));

        if (payment.getStatus() == PaymentStatus.REFUNDED) {
            return coinService.getBalance(payment.getStudentId());
        }
        if (payment.getStatus() != PaymentStatus.COMPLETED) {
            throw BusinessException.conflict("환불 처리할 수 없는 결제 상태입니다: " + payment.getStatus());
        }

        int totalCoinToRefund = payment.getCoinAmount() +
                (payment.getBonusCoinAmount() != null ? payment.getBonusCoinAmount() : 0);
        CoinBalanceResponse balance = coinService.refund(
                payment.getStudentId(), totalCoinToRefund, payment.getId());

        payment.refund();
        return balance;
    }
}
