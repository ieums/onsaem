package com.ieum.backend.domain.payment.exception;

public class PaymentAmountMismatchException extends PaymentVerificationException {
    public PaymentAmountMismatchException(int expected, int actual) {
        super(String.format("결제 금액 불일치. expected=%d, actual=%d", expected, actual));
    }
}