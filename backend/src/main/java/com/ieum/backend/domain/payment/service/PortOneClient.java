package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.external.PortOnePaymentResponse;
import com.ieum.backend.domain.payment.exception.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;

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
            throw e;
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

    /**
     * V2 결제 취소 (환불)
     * POST /payments/{paymentId}/cancel
     */
    public void cancelPayment(String portonePaymentId, String reason) {
        if (!verificationEnabled) {
            log.warn("[PortOne] 테스트 모드 — 결제 취소 건너뜀. paymentId={}", portonePaymentId);
            return;
        }

        log.info("[PortOne] 결제 취소 시작. paymentId={}, reason={}", portonePaymentId, reason);

        try {
            portOneRestClient.post()
                    .uri("/payments/{paymentId}/cancel", portonePaymentId)
                    .body(Map.of(
                            "reason", reason != null ? reason : "사용자 요청"
                    ))
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, (req, res) -> {
                        if (res.getStatusCode().value() == 404) {
                            throw new PortOnePaymentNotFoundException(portonePaymentId);
                        }
                        throw new PaymentVerificationException(
                                "포트원 결제 취소 4xx 오류: " + res.getStatusCode());
                    })
                    .onStatus(HttpStatusCode::is5xxServerError, (req, res) -> {
                        throw new PaymentVerificationException(
                                "포트원 결제 취소 5xx 오류: " + res.getStatusCode());
                    })
                    .toBodilessEntity();

            log.info("[PortOne] 결제 취소 성공. paymentId={}", portonePaymentId);
        } catch (PaymentVerificationException e) {
            throw e;
        } catch (Exception e) {
            log.error("[PortOne] 결제 취소 API 호출 실패. paymentId={}", portonePaymentId, e);
            throw new PaymentVerificationException("포트원 결제 취소 API 호출 실패", e);
        }
    }
}