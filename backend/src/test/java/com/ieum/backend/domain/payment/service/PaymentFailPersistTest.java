package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.request.CoinChargeRequest;
import com.ieum.backend.domain.payment.dto.response.PaymentResponse;
import com.ieum.backend.domain.payment.entity.CoinPackage;
import com.ieum.backend.domain.payment.entity.enums.PaymentStatus;
import com.ieum.backend.domain.payment.repository.CoinPackageRepository;
import com.ieum.backend.domain.payment.repository.PaymentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;

/**
 * #4 버그 회귀 방지: 포트원 검증 실패 시 결제가 FAILED로 "보존"되는지 검증.
 *
 * 예전엔 같은 트랜잭션에서 payment.fail() 후 예외를 re-throw → 롤백으로 fail()이 사라졌다.
 * 이제 markFailed가 REQUIRES_NEW 별도 트랜잭션이라 메인 롤백과 무관하게 커밋되어야 한다.
 */
@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("결제 검증 실패 시 FAILED 보존")
class PaymentFailPersistTest {

    @Autowired PaymentService paymentService;
    @Autowired PaymentRepository paymentRepository;
    @Autowired CoinPackageRepository coinPackageRepository;

    @MockBean PortOneClient portOneClient;   // 검증을 강제로 실패시킴

    private String merchantId;

    @BeforeEach
    void setUp() {
        paymentRepository.deleteAll();
        coinPackageRepository.deleteAll();

        CoinPackage pkg = coinPackageRepository.save(CoinPackage.builder()
                .name("테스트 100코인").price(1000).coinAmount(100).bonusAmount(0).build());

        PaymentResponse created = paymentService.createCoinPayment(
                8800L, new CoinChargeRequest(8800L, pkg.getId()));
        this.merchantId = created.getMerchantId();
    }

    @Test
    @DisplayName("검증이 실패하면 예외가 나도 결제 상태는 FAILED로 남는다")
    void verifyFails_paymentStaysFailed() {
        given(portOneClient.verifyPayment(anyString(), anyInt()))
                .willThrow(new RuntimeException("포트원 검증 실패"));

        assertThatThrownBy(() ->
                paymentService.completeCoinPayment(merchantId, "PORTONE-X", "CARD"))
                .isInstanceOf(RuntimeException.class);

        PaymentStatus status = paymentRepository.findByMerchantId(merchantId)
                .orElseThrow().getStatus();
        System.out.println("[검증실패 보존] status=" + status);
        org.assertj.core.api.Assertions.assertThat(status).isEqualTo(PaymentStatus.FAILED);
    }
}
