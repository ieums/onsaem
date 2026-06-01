package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.external.PortOnePaymentResponse;
import com.ieum.backend.domain.payment.exception.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Slf4j
@Component
@RequiredArgsConstructor
public class PortOneClient {

    private final RestClient portOneRestClient;
    @Value("${portone.verification-enabled:false}")
    private boolean verificationEnabled;

    /**
     * V2 결제 검증
     */
    public PortOnePaymentResponse verifyPayment(String paymentId, int expectedAmount) {
        if (!verificationEnabled) {
            log.warn("[PortOne] 테스트 모드 — 검증 건너뜀.");
            return null;
        }

        log.info("[PortOne] 검증 시작. paymentId={}, expected={}", paymentId, expectedAmount);


        PortOnePaymentResponse response;
        try {
            response = portOneRestClient.get()
                    .uri("/payments/{paymentId}", paymentId)
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, (req, res) -> {
                        if (res.getStatusCode().value() == 404) {
                            throw new PortOnePaymentNotFoundException(paymentId);
                        }
                        throw new PaymentVerificationException(
                                "포트원 4xx 오류: " + res.getStatusCode());
                    })
                    .onStatus(HttpStatusCode::is5xxServerError, (req, res) -> {
                        throw new PaymentVerificationException(
                                "포트원 5xx 오류: " + res.getStatusCode());
                    })
                    .body(PortOnePaymentResponse.class);
        } catch (PaymentVerificationException e) {
            throw e;  // 위에서 던진 거 그대로 전파
        } catch (Exception e) {
            log.error("[PortOne] API 호출 실패. paymentId={}", paymentId, e);
            throw new PaymentVerificationException("포트원 API 호출 실패", e);
        }

        if (response == null) {
            throw new PortOnePaymentNotFoundException(paymentId);
        }

        log.info("[PortOne] 응답 받음. status={}, amount={}",
                response.status(), response.amount().total());

        if (!"PAID".equals(response.status())) {
            throw new PaymentNotCompletedException(response.status());
        }

        int actualAmount = (int) response.amount().total();
        if (actualAmount != expectedAmount) {
            throw new PaymentAmountMismatchException(expectedAmount, actualAmount);
        }

        log.info("[PortOne] 검증 성공.");
        return response;
    }
}