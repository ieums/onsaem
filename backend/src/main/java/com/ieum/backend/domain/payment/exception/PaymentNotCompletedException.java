package com.ieum.backend.domain.payment.exception;

public class PaymentNotCompletedException extends PaymentVerificationException {
    public PaymentNotCompletedException(String status) {
        super("결제가 완료되지 않은 상태입니다. status=" + status);
    }
}