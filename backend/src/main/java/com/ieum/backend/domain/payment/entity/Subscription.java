package com.ieum.backend.domain.payment.entity;


import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "subscriptions")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Subscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long studentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name="subscription_plan_id")
    private SubscriptionPlan subscriptionPlan;

    @Column(nullable = false)
    private LocalDate startDate;

    @Column(nullable = false)
    private LocalDate endDate;

    @Column(nullable = false)
    private Boolean autoRenew;

    @Column(length = 100)
    private String billingKey;

    @Column(nullable = false)
    private Boolean active;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Builder
    public Subscription(Long studentId, SubscriptionPlan subscriptionPlan, Boolean autoRenew) {
        this.studentId = studentId;
        this.subscriptionPlan = subscriptionPlan;
        this.startDate = LocalDate.now();
        this.endDate = LocalDate.now().plusDays(subscriptionPlan.getDurationDays());
        this.autoRenew = autoRenew != null ? autoRenew : false;
        this.active = true;
        this.createdAt = LocalDateTime.now();
    }

    // 구독 활성 상태 확인
    public boolean isValid() {
        return this.active && LocalDate.now().isBefore(this.endDate);
    }

    // 구독 갱신
    public void renew() {
        this.startDate = this.endDate;
        this.endDate = this.startDate.plusDays(subscriptionPlan.getDurationDays());
    }

    // 구독 취소
    public void cancel() {
        this.autoRenew = false;
        // 남은 기간은 유지, 갱신만 안 됨
    }

    // 구독 만료
    public void expire() {
        this.active = false;
    }
}