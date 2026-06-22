package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.request.CoinChargeRequest;
import com.ieum.backend.domain.payment.dto.response.PaymentResponse;
import com.ieum.backend.domain.payment.entity.CoinPackage;
import com.ieum.backend.domain.payment.entity.enums.TransactionType;
import com.ieum.backend.domain.payment.repository.CoinPackageRepository;
import com.ieum.backend.domain.payment.repository.CoinTransactionRepository;
import com.ieum.backend.domain.payment.repository.CoinWalletRepository;
import com.ieum.backend.domain.payment.repository.PaymentRepository;
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
 * 결제 완료 동시 요청(race condition) 검증.
 *
 * 같은 merchantId 결제 1건을 두 스레드가 "동시에" 완료 처리할 때
 * 코인이 한 번만 적립되는지(멱등성)를 확인한다.
 *
 * - 상태 가드만 있고 DB 락이 없으면: 두 스레드가 모두 PENDING을 읽어
 *   둘 다 통과 → CHARGE 트랜잭션 2건 (테스트 실패).
 * - findByMerchantId에 비관적 락(또는 @Version)을 적용하면: 1건 (테스트 통과).
 */
@SpringBootTest
// local 프로파일은 LocalImageStorageService 빈을 위해 필요.
// test를 뒤에 둬서 datasource(H2)·ddl-auto·sql.init를 local(MySQL) 위에 덮어쓴다.
@ActiveProfiles({"local", "test"})
@DisplayName("결제 완료 동시 요청 멱등성")
class PaymentConcurrencyTest {

    @Autowired PaymentService paymentService;
    @Autowired CoinService coinService;
    @Autowired PaymentRepository paymentRepository;
    @Autowired CoinPackageRepository coinPackageRepository;
    @Autowired CoinWalletRepository coinWalletRepository;
    @Autowired CoinTransactionRepository coinTransactionRepository;

    private static final long STUDENT_ID = 9001L;
    private static final int COIN_AMOUNT = 100;

    private String merchantId;

    @BeforeEach
    void setUp() {
        // 깨끗한 상태로 시작
        coinTransactionRepository.deleteAll();
        paymentRepository.deleteAll();
        coinWalletRepository.deleteAll();
        coinPackageRepository.deleteAll();

        // 보너스 0짜리 패키지 → 완료 1회당 CHARGE 트랜잭션 정확히 1건
        CoinPackage pkg = coinPackageRepository.save(CoinPackage.builder()
                .name("테스트 100코인")
                .price(1000)
                .coinAmount(COIN_AMOUNT)
                .bonusAmount(0)
                .build());

        // 지갑 미리 생성 (지갑 생성 race를 제거하고 결제-상태 race만 검증)
        coinService.getOrCreateWallet(STUDENT_ID);

        // PENDING 결제 1건 생성
        PaymentResponse created = paymentService.createCoinPayment(
                new CoinChargeRequest(STUDENT_ID, pkg.getId()));
        this.merchantId = created.getMerchantId();
    }

    @AfterEach
    void tearDown() {
        coinTransactionRepository.deleteAll();
        paymentRepository.deleteAll();
        coinWalletRepository.deleteAll();
        coinPackageRepository.deleteAll();
    }

    @Test
    @DisplayName("같은 결제를 동시에 두 번 완료해도 코인은 한 번만 적립된다")
    void completeCoinPayment_concurrent_chargesOnlyOnce() throws Exception {
        int threads = 2;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CyclicBarrier barrier = new CyclicBarrier(threads); // 두 스레드를 같은 시점에 출발시킴
        List<Future<?>> futures = new ArrayList<>();
        List<Throwable> errors = new ArrayList<>();

        for (int i = 0; i < threads; i++) {
            futures.add(pool.submit(() -> {
                try {
                    barrier.await();
                    paymentService.completeCoinPayment(merchantId, "PORTONE-TEST", "CARD");
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

        long chargeCount = coinTransactionRepository
                .findByStudentIdAndTypeOrderByCreatedAtDesc(STUDENT_ID, TransactionType.CHARGE)
                .size();
        int balance = coinWalletRepository.findByStudentId(STUDENT_ID)
                .orElseThrow().getBalance();

        System.out.println("[동시성 테스트] CHARGE 트랜잭션 수 = " + chargeCount
                + ", 잔액 = " + balance
                + ", 동시 처리 중 예외 수 = " + errors.size());

        assertThat(chargeCount)
                .as("동일 결제건이 동시에 두 번 완료되면 코인이 중복 적립된다 — 멱등성 깨짐")
                .isEqualTo(1);
        assertThat(balance)
                .as("잔액도 1회 충전분만 반영되어야 한다")
                .isEqualTo(COIN_AMOUNT);
    }
}
