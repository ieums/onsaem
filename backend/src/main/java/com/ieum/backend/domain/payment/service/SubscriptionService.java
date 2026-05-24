package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.request.SubscribeRequest;
import com.ieum.backend.domain.payment.dto.response.SubscriptionResponse;
import com.ieum.backend.domain.payment.entity.Subscription;
import com.ieum.backend.domain.payment.entity.SubscriptionPlan;
import com.ieum.backend.domain.payment.repository.SubscriptionPlanRepository;
import com.ieum.backend.domain.payment.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final SubscriptionPlanRepository planRepository;

    /**
     * 구독 시작
     */
    @Transactional
    public SubscriptionResponse subscribe(SubscribeRequest request) {
        // 기존 활성 구독 확인
        subscriptionRepository.findByStudentIdAndActiveTrue(request.getStudentId())
                .ifPresent(existing -> {
                    throw new RuntimeException("이미 활성 구독이 있습니다. 기존 구독: " + existing.getId());
                });

        SubscriptionPlan plan = planRepository.findById(request.getPlanId())
                .orElseThrow(() -> new RuntimeException("존재하지 않는 구독 플랜입니다."));

        Subscription subscription = Subscription.builder()
                .studentId(request.getStudentId())
                .subscriptionPlan(plan)
                .autoRenew(request.getAutoRenew())
                .build();

        subscriptionRepository.save(subscription);
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
                .orElseThrow(() -> new RuntimeException("활성 구독이 없습니다."));

        subscription.cancel();
        return SubscriptionResponse.from(subscription);
    }
}