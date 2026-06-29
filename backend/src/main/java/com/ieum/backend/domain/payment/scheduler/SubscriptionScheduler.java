package com.ieum.backend.domain.payment.scheduler;

import com.ieum.backend.domain.payment.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 구독 만료 정리 — 기간이 끝난(endDate 경과) 활성 구독을 비활성화하고 활성 슬롯을 해제한다.
 * 해지(자동갱신 OFF)한 구독은 endDate까지 유지되다가 여기서 자연 만료된다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SubscriptionScheduler {

    private final SubscriptionService subscriptionService;

    /** 1시간마다 만료 구독 정리. */
    @Scheduled(fixedDelay = 3_600_000)
    public void expireDue() {
        try {
            int expired = subscriptionService.expireDueSubscriptions();
            if (expired > 0) log.info("만료 구독 {}건 정리 완료", expired);
        } catch (RuntimeException e) {
            log.warn("구독 만료 처리 실패(다음 주기 재시도): {}", e.getMessage());
        }
    }
}
