package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.request.CoinChargeRequest;
import com.ieum.backend.domain.payment.dto.response.CoinBalanceResponse;
import com.ieum.backend.domain.payment.dto.response.PaymentResponse;
import com.ieum.backend.domain.payment.entity.CoinPackage;
import com.ieum.backend.domain.payment.entity.Payment;
import com.ieum.backend.domain.payment.entity.enums.PaymentMethod;
import com.ieum.backend.domain.payment.repository.CoinPackageRepository;
import com.ieum.backend.domain.payment.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final CoinPackageRepository coinPackageRepository;
    private final CoinService coinService;
    private final PortOneClient portOneClient;

    /**
     * 결제 요청 생성 (포트원 결제창 호출 전)
     */
    @Transactional
    public PaymentResponse createPayment(CoinChargeRequest request) {
        CoinPackage coinPackage = coinPackageRepository.findById(request.getCoinPackageId())
                .orElseThrow(() -> new RuntimeException("존재하지 않는 코인 패키지입니다."));

        String merchantId = "PAY-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Payment payment = Payment.builder()
                .merchantId(merchantId)
                .studentId(request.getStudentId())
                .amount(coinPackage.getPrice())
                .coinAmount(coinPackage.getCoinAmount())
                .bonusCoinAmount(coinPackage.getBonusAmount())
                .productName(coinPackage.getName() + " 충전")
                .build();

        paymentRepository.save(payment);
        return PaymentResponse.from(payment);
    }

    /**
     * 결제 완료 처리 (V2)
     * @param merchantId  우리가 발급한 주문번호 (createPayment 시점에 만든 것)
     * @param paymentId   포트원 V2 paymentId (프론트가 전달)
     * @param method      결제 수단 ("CARD", "KAKAOPAY" 등)
     */
    @Transactional
    public CoinBalanceResponse completePayment(String merchantId, String paymentId, String method) {
        Payment payment = paymentRepository.findByMerchantId(merchantId)
                .orElseThrow(() -> new RuntimeException("결제 정보를 찾을 수 없습니다."));

        try {
            portOneClient.verifyPayment(paymentId, payment.getAmount());
        } catch (Exception e) {
            payment.fail();
            paymentRepository.save(payment);
            throw e;
        }

        PaymentMethod paymentMethod = PaymentMethod.fromString(method);
        payment.complete(paymentId, paymentMethod);

        return coinService.charge(
                payment.getStudentId(),
                payment.getCoinAmount(),
                payment.getBonusCoinAmount(),
                payment.getId()
        );
    }
    /**
     * 결제 실패 처리
     */
    @Transactional
    public void failPayment(String merchantId) {
        Payment payment = paymentRepository.findByMerchantId(merchantId)
                .orElseThrow(() -> new RuntimeException("결제 정보를 찾을 수 없습니다."));
        payment.fail();
    }

    /**
     * 결제 내역 조회
     */
    public List<PaymentResponse> getPayments(Long studentId) {
        return paymentRepository.findByStudentIdOrderByCreatedAtDesc(studentId)
                .stream()
                .map(PaymentResponse::from)
                .collect(Collectors.toList());
    }
}