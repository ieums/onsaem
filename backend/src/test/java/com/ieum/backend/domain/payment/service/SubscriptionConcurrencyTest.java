package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.entity.SubscriptionPlan;
import com.ieum.backend.domain.payment.repository.SubscriptionPlanRepository;
import com.ieum.backend.domain.payment.repository.SubscriptionRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 구독 중복 활성화(race condition) 검증.
 *
 * 같은 학생의 서로 다른 결제 2건이 "동시에" 구독을 활성화할 때
 * 활성 구독이 한 건만 만들어지는지 확인한다.
 *
 * - 앱 체크만 있으면: 둘 다 "활성 없음"을 읽어 2건 활성화 (실패).
 * - active_student_id UNIQUE 제약이 있으면: 두 번째가 막혀 1건 (통과).
 */
@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("구독 동시 활성화 중복 방지")
class SubscriptionConcurrencyTest {

    @Autowired SubscriptionService subscriptionService;
    @Autowired SubscriptionRepository subscriptionRepository;
    @Autowired SubscriptionPlanRepository planRepository;

    private static final long STUDENT_ID = 6001L;

    private Long planId;

    @BeforeEach
    void setUp() {
        subscriptionRepository.deleteAll();
        planRepository.deleteAll();
        SubscriptionPlan plan = planRepository.save(SubscriptionPlan.builder()
                .name("AI 튜터 월간")
                .price(9900)
                .durationDays(30)
                .discountPercent(0)
                .build());
        this.planId = plan.getId();
    }

    @AfterEach
    void tearDown() {
        subscriptionRepository.deleteAll();
        planRepository.deleteAll();
    }

    @Test
    @DisplayName("같은 학생의 구독을 동시에 활성화해도 활성 구독은 한 건만 생성된다")
    void activate_concurrent_createsOnlyOneActive() throws Exception {
        int threads = 2;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CyclicBarrier barrier = new CyclicBarrier(threads);
        List<Future<?>> futures = new ArrayList<>();
        List<Throwable> errors = new ArrayList<>();

        for (int i = 0; i < threads; i++) {
            final long paymentId = 100L + i;
            futures.add(pool.submit(() -> {
                try {
                    barrier.await();
                    subscriptionService.activateAfterPayment(
                            STUDENT_ID, planId, 9900, false, paymentId);
                } catch (Throwable t) {
                    synchronized (errors) {
                        errors.add(t);
                    }
                }
                return null;
            }));
        }

        for (Future<?> f : futures) {
            f.get();
        }
        pool.shutdown();

        long activeCount = subscriptionRepository
                .findByStudentIdOrderByCreatedAtDesc(STUDENT_ID).stream()
                .filter(s -> Boolean.TRUE.equals(s.getActive()))
                .count();

        System.out.println("[구독 동시성] 활성 구독 수 = " + activeCount
                + ", 거부된 요청 수 = " + errors.size());

        assertThat(activeCount)
                .as("같은 학생의 활성 구독이 동시에 두 건 생기면 안 된다 — UNIQUE 제약으로 1건만")
                .isEqualTo(1);
        assertThat(errors)
                .as("동시 요청 중 한쪽은 거부되어야 한다")
                .hasSize(1);
    }
}
