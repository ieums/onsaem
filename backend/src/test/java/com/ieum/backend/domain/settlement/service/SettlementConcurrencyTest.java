package com.ieum.backend.domain.settlement.service;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.settlement.dto.request.CalculateSettlementRequest;
import com.ieum.backend.domain.settlement.repository.SettlementRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 정산 중복 생성(race condition) 검증.
 *
 * 같은 lessonId 정산을 두 스레드가 "동시에" 생성할 때
 * 정산이 한 건만 만들어지는지 확인한다.
 *
 * - findByLessonId 앱 체크만 있으면: 둘 다 "없음"을 읽어 2건 생성 (실패).
 * - settlements.lesson_id UNIQUE 제약이 있으면: 두 번째 insert가 막혀 1건 (통과).
 */
@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("정산 동시 생성 중복 방지")
class SettlementConcurrencyTest {

    @Autowired SettlementService settlementService;
    @Autowired SettlementRepository settlementRepository;
    @Autowired LessonRepository lessonRepository;

    private static final long TUTOR_ID = 7001L;
    private static final long STUDENT_ID = 9001L;
    private static final int TOTAL_COIN = 100;

    // 정산은 강의에서 강사를 권위있게 가져오므로, 실제 Lesson 행을 만들고 그 id를 쓴다.
    private Long lessonId;

    @BeforeEach
    void setUp() {
        settlementRepository.deleteAll();
        // 정산은 강사·금액을 모두 강의에서 가져오므로, coinCost가 있는 '과금 강의'여야 한다.
        // (startBilling 없이 만들면 calculate()가 "과금 강의가 아님"으로 거부한다)
        Lesson lesson = new Lesson("ch-settle-concurrency", TUTOR_ID, STUDENT_ID);
        lesson.startBilling(STUDENT_ID, TUTOR_ID, TOTAL_COIN, LocalDateTime.now().plusMinutes(30));
        lessonId = lessonRepository.save(lesson).getId();
    }

    @AfterEach
    void tearDown() {
        settlementRepository.deleteAll();
        if (lessonId != null) lessonRepository.deleteById(lessonId);
    }

    @Test
    @DisplayName("같은 강의를 동시에 정산해도 정산은 한 건만 생성된다")
    void calculate_concurrent_createsOnlyOne() throws Exception {
        int threads = 2;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CyclicBarrier barrier = new CyclicBarrier(threads);
        List<Future<?>> futures = new ArrayList<>();
        List<Throwable> errors = new ArrayList<>();

        for (int i = 0; i < threads; i++) {
            futures.add(pool.submit(() -> {
                try {
                    barrier.await();
                    settlementService.calculate(
                            new CalculateSettlementRequest(lessonId));
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

        long count = settlementRepository.findByTutorIdOrderByCreatedAtDesc(TUTOR_ID).size();

        System.out.println("[정산 동시성] 생성된 정산 수 = " + count
                + ", 거부된 요청 수 = " + errors.size());

        assertThat(count)
                .as("같은 lessonId 정산이 동시에 두 번 생성되면 안 된다 — UNIQUE 제약으로 1건만")
                .isEqualTo(1);
        // 동시 요청 중 한쪽은 거부(예외)되어야 정상
        assertThat(errors).hasSize(1);
    }
}
