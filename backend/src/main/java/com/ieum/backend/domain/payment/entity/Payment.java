package com.ieum.backend.domain.payment.entity;

import com.ieum.backend.domain.payment.entity.enums.PaymentMethod;
import com.ieum.backend.domain.payment.entity.enums.PaymentStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "payments")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 50)
    private String merchantId;

    @Column(length = 100)
    private String portonePaymentId;

    @Column(nullable = false)
    private Long studentId;

    @Column(nullable = false)
    private Integer amount;

    private Integer coinAmount;
    private Integer bonusCoinAmount;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private PaymentMethod method;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PaymentStatus status;

    @Column(length = 100)
    private String productName;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime completedAt;

    @Builder
    public Payment(String merchantId, Long studentId, Integer amount,
                   Integer coinAmount, Integer bonusCoinAmount,
                   String productName) {
        this.merchantId = merchantId;
        this.studentId = studentId;
        this.amount = amount;
        this.coinAmount = coinAmount;
        this.bonusCoinAmount = bonusCoinAmount;
        this.productName = productName;
        this.status = PaymentStatus.PENDING;
        this.createdAt = LocalDateTime.now();
    }

    // 결제 완료
    public void complete(String portonePaymentId, PaymentMethod method) {
        this.portonePaymentId = portonePaymentId;
        this.method = method;
        this.status = PaymentStatus.COMPLETED;
        this.completedAt = LocalDateTime.now();
    }

    // 결제 실패
    public void fail() {
        this.status = PaymentStatus.FAILED;
    }

    // 결제 취소
    public void cancel() {
        this.status = PaymentStatus.CANCELED;
    }

    // 환불
    public void refund() {
        this.status = PaymentStatus.REFUNDED;
    }
}