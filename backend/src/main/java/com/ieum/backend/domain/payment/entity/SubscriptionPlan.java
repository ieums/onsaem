package com.ieum.backend.domain.payment.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "subscription_plans")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SubscriptionPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String name;                // "AI 튜터 월간"

    @Column(nullable = false)
    private Integer price;              // 9900 (원)

    @Column(nullable = false)
    private Integer durationDays;       // 30, 365

    private Integer discountPercent;    // 연간이면 30 (30% 할인)

    @Column(nullable = false)
    private Boolean active;             // 판매 중인지

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @Builder
    public SubscriptionPlan(String name, Integer price, Integer durationDays,
                            Integer discountPercent) {
        this.name = name;
        this.price = price;
        this.durationDays = durationDays;
        this.discountPercent = discountPercent != null ? discountPercent : 0;
        this.active = true;
        this.createdAt = LocalDateTime.now();
    }

    // 가격 변경
    public void updatePrice(Integer price, Integer discountPercent) {
        this.price = price;
        if (discountPercent != null) this.discountPercent = discountPercent;
        this.updatedAt = LocalDateTime.now();
    }

    // 판매 중지
    public void deactivate() {
        this.active = false;
        this.updatedAt = LocalDateTime.now();
    }

    // 판매 재개
    public void activate() {
        this.active = true;
        this.updatedAt = LocalDateTime.now();
    }
}