package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.response.SubscriptionResponse;
import com.ieum.backend.domain.payment.entity.Subscription;
import com.ieum.backend.domain.payment.entity.SubscriptionPlan;
import com.ieum.backend.domain.payment.repository.SubscriptionPlanRepository;
import com.ieum.backend.domain.payment.repository.SubscriptionRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final SubscriptionPlanRepository planRepository;

    /**
     * 활성 구독 없는지 확인 (결제 요청 전 사전 체크)
     * PaymentService.createSubscriptionPayment에서 호출
     */
    public void checkNoActiveSubscription(Long studentId) {
        subscriptionRepository.findByStudentIdAndActiveTrue(studentId)
                .ifPresent(existing -> {
                    throw BusinessException.conflict("이미 활성 구독이 있습니다. 기존 구독: " + existing.getId());
                });
    }

    /**
     * 결제 완료 후 구독 활성화
     * PaymentService.completeSubscriptionPayment에서 호출
     *
     * @param studentId  학생 ID
     * @param planId     구독 플랜 ID
     * @param paidPrice  실제 결제 금액
     * @param autoRenew  자동 갱신 여부
     * @param paymentId  Payment 엔티티 ID (FK 연결용, 필요 없으면 무시 가능)
     */
    @Transactional
    public SubscriptionResponse activateAfterPayment(
            Long studentId,
            Long planId,
            int paidPrice,
            boolean autoRenew,
            Long paymentId
    ) {
        // 1차 방어: 앱 레벨 체크 (일반 경로의 친절한 에러)
        checkNoActiveSubscription(studentId);

        SubscriptionPlan plan = planRepository.findById(planId)
                .orElseThrow(() -> BusinessException.notFound("존재하지 않는 구독 플랜입니다."));

        Subscription subscription = Subscription.builder()
                .studentId(studentId)
                .subscriptionPlan(plan)
                .autoRenew(autoRenew)
                .build();

        // 2차 방어: 서로 다른 결제 2건이 동시에 활성화돼 위 체크를 둘 다 통과해도
        // active_student_id UNIQUE 제약이 두 번째 활성 구독 생성을 DB에서 막는다.
        try {
            subscriptionRepository.saveAndFlush(subscription);
        } catch (DataIntegrityViolationException e) {
            throw BusinessException.conflict("이미 활성 구독이 있습니다. studentId: " + studentId, e);
        }
        return SubscriptionResponse.from(subscription);
    }

    /**
     * 내 구독 조회
     */
    public SubscriptionResponse getMySubscription(Long studentId) {
        Subscription subscription = subscriptionRepository.findByStudentIdAndActiveTrue(studentId)
                .orElse(null);

        if (subscription == null) return null;
        return SubscriptionResponse.from(subscription);
    }

    /**
     * AI 튜터 사용 가능 여부 (구독 활성 중인지)
     */
    public boolean hasActiveSubscription(Long studentId) {
        return subscriptionRepository.findByStudentIdAndActiveTrue(studentId)
                .map(Subscription::isValid)
                .orElse(false);
    }

    /**
     * 구독 취소 (자동갱신 OFF, 남은 기간은 유지)
     */
    @Transactional
    public SubscriptionResponse cancelSubscription(Long studentId) {
        Subscription subscription = subscriptionRepository.findByStudentIdAndActiveTrue(studentId)
                .orElseThrow(() -> BusinessException.notFound("활성 구독이 없습니다."));

        subscription.cancel(); // 자동갱신만 OFF — endDate까지 이용 유지(즉시 사라지지 않음)
        return SubscriptionResponse.from(subscription);
    }

    // ── 관리자 콘솔: 구독 조회·해지 ──

    @Transactional(readOnly = true)
    public org.springframework.data.domain.Page<Subscription> getSubscriptionsForAdmin(
            org.springframework.data.domain.Pageable pageable) {
        return subscriptionRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    /** 관리자 해지 — 자동갱신만 OFF(기간은 유지). */
    @Transactional
    public void cancelByAdmin(Long subscriptionId) {
        subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> BusinessException.notFound("구독을 찾을 수 없습니다."))
                .cancel();
    }

    /** 관리자 즉시 만료 — active=false + 활성 슬롯 해제(재구독 가능). */
    @Transactional
    public void expireByAdmin(Long subscriptionId) {
        subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> BusinessException.notFound("구독을 찾을 수 없습니다."))
                .expire();
    }

    /**
     * 기간이 끝난(endDate 경과) 활성 구독을 만료 처리 — 스케줄러가 주기 호출.
     * active=false + 활성 슬롯 해제(재구독 가능). 해지(autoRenew OFF)한 구독은 여기서 자연 만료된다.
     * TODO: PG 자동결제 연동 시 autoRenew=true는 만료 대신 renew()+재결제로 분기.
     */
    @Transactional
    public int expireDueSubscriptions() {
        List<Subscription> due =
                subscriptionRepository.findByActiveTrueAndEndDateLessThanEqual(LocalDate.now());
        due.forEach(Subscription::expire);
        return due.size();
    }
    /**
     * 자동갱신 토글
     * @param studentId 학생 ID
     * @param autoRenew true면 ON, false면 OFF
     */
    @Transactional
    public SubscriptionResponse toggleAutoRenew(Long studentId, boolean autoRenew) {
        Subscription subscription = subscriptionRepository.findByStudentIdAndActiveTrue(studentId)
                .orElseThrow(() -> BusinessException.notFound("활성 구독이 없습니다."));

        subscription.updateAutoRenew(autoRenew);
        return SubscriptionResponse.from(subscription);
    }
}