package com.ieum.backend.domain.payment.entity;


import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "subscriptions",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_subscriptions_active_student",
                columnNames = "active_student_id"
        )
)
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

    /**
     * 활성 구독 1건 보장용 파생 컬럼.
     * 활성이면 studentId, 비활성이면 NULL.
     * UNIQUE 인덱스 + MySQL의 "NULL은 중복 허용" 특성으로
     * 학생당 활성 구독이 DB 차원에서 최대 1건이 되도록 강제한다.
     */
    @Column(name = "active_student_id")
    private Long activeStudentId;

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
        this.activeStudentId = studentId;   // 활성이므로 파생 컬럼 = studentId
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

    // 구독 자동갱신
    public void updateAutoRenew(boolean autoRenew) {
        this.autoRenew = autoRenew;
    }

    // 구독 취소(즉시 종료) — 활성 해제 + 자동갱신 OFF + 활성 슬롯(파생 컬럼) 비움(재구독 가능)
    public void cancel() {
        this.active = false;
        this.autoRenew = false;
        this.activeStudentId = null;
    }

    // 구독 만료
    public void expire() {
        this.active = false;
        this.activeStudentId = null;   // 비활성 → 파생 컬럼 NULL (다음 구독이 활성 슬롯 차지 가능)
    }
}