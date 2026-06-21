package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.entity.CoinWallet;
import com.ieum.backend.domain.payment.repository.CoinTransactionRepository;
import com.ieum.backend.domain.payment.repository.CoinWalletRepository;
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
 * 코인 지갑 잔액 변경 동시성 검증.
 *
 * 잔액 5코인 지갑에 3코인짜리 AI 사용을 두 스레드가 "동시에" 요청한다.
 * 정상이면 한 번만 성공해야 한다(5 - 3 = 2). 두 번 빠지면 음수(-1).
 *
 * - 락이 없으면: 둘 다 availableBalance=5를 읽고 통과 → 음수 잔액 (실패).
 * - findByStudentIdForUpdate 비관적 락이 있으면: 두 번째는 대기 후
 *   availableBalance=2를 읽고 잔액 부족으로 거부 → 음수 없음 (통과).
 */
@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("코인 지갑 동시 차감")
class WalletConcurrencyTest {

    @Autowired CoinService coinService;
    @Autowired CoinWalletRepository walletRepository;
    @Autowired CoinTransactionRepository transactionRepository;

    private static final long STUDENT_ID = 5001L;

    @BeforeEach
    void setUp() {
        transactionRepository.deleteAll();
        walletRepository.deleteAll();
        // 잔액 5코인으로 시작 (AI 1회=3코인 → 1번만 가능)
        coinService.charge(STUDENT_ID, 5, 0, null);
    }

    @AfterEach
    void tearDown() {
        transactionRepository.deleteAll();
        walletRepository.deleteAll();
    }

    @Test
    @DisplayName("잔액 5코인에서 3코인 AI 사용을 동시에 두 번 해도 음수가 되지 않는다")
    void useForAi_concurrent_neverGoesNegative() throws Exception {
        int threads = 2;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CyclicBarrier barrier = new CyclicBarrier(threads);
        List<Future<?>> futures = new ArrayList<>();
        List<Throwable> errors = new ArrayList<>();

        for (int i = 0; i < threads; i++) {
            futures.add(pool.submit(() -> {
                try {
                    barrier.await();
                    coinService.useForAi(STUDENT_ID);
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

        CoinWallet wallet = walletRepository.findByStudentId(STUDENT_ID).orElseThrow();

        System.out.println("[지갑 동시성] balance=" + wallet.getBalance()
                + ", available=" + wallet.getAvailableBalance()
                + ", 거부된 요청 수 = " + errors.size());

        assertThat(wallet.getAvailableBalance())
                .as("동시 차감으로 음수가 되면 안 된다 — 한 번만 성공(5-3=2)")
                .isEqualTo(2);
        assertThat(wallet.getBalance()).isEqualTo(2);
        assertThat(errors)
                .as("두 동시 요청 중 한쪽은 잔액 부족으로 거부되어야 한다")
                .hasSize(1);
    }
}
