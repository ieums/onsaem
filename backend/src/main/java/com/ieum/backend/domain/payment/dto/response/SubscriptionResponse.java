package com.ieum.backend.domain.payment.dto.response;

import com.ieum.backend.domain.payment.entity.Subscription;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class SubscriptionResponse {

    private Long id;
    private Long studentId;
    private Long planId;
    private Integer paidPrice;
    private LocalDate startDate;
    private LocalDate endDate;
    private Boolean autoRenew;
    private Boolean active;
    private Boolean valid;
    private LocalDateTime createdAt;

    public static SubscriptionResponse from(Subscription sub) {
        return SubscriptionResponse.builder()
                .id(sub.getId())
                .studentId(sub.getStudentId())
                .planId(sub.getSubscriptionPlan().getId())
                .paidPrice(sub.getSubscriptionPlan().getPrice())
                .startDate(sub.getStartDate())
                .endDate(sub.getEndDate())
                .autoRenew(sub.getAutoRenew())
                .active(sub.getActive())
                .valid(sub.isValid())
                .createdAt(sub.getCreatedAt())
                .build();
    }
}