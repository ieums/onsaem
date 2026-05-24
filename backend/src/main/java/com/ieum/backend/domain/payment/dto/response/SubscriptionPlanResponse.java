package com.ieum.backend.domain.payment.dto.response;

import com.ieum.backend.domain.payment.entity.SubscriptionPlan;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class SubscriptionPlanResponse {

    private Long id;
    private String name;
    private Integer price;
    private Integer durationDays;
    private Integer discountPercent;

    public static SubscriptionPlanResponse from(SubscriptionPlan plan) {
        return SubscriptionPlanResponse.builder()
                .id(plan.getId())
                .name(plan.getName())
                .price(plan.getPrice())
                .durationDays(plan.getDurationDays())
                .discountPercent(plan.getDiscountPercent())
                .build();
    }
}