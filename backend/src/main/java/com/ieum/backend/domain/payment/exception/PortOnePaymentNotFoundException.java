package com.ieum.backend.domain.payment.exception;

public class PortOnePaymentNotFoundException extends PaymentVerificationException {
    public PortOnePaymentNotFoundException(String paymentId) {
        super("포트원에 결제 정보가 없습니다. paymentId=" + paymentId);
    }
}