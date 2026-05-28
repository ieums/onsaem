package com.ieum.backend.domain.payment.entity;

import com.ieum.backend.domain.payment.entity.enums.TransactionType;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "coin_transactions")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CoinTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long studentId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TransactionType type;

    @Column(nullable = false)
    private Integer amount;           // + 충전, - 차감

    @Column(nullable = false)
    private Integer balanceAfter;     // 거래 후 잔액

    private Long lessonId;            // 강의 관련이면

    private Long paymentId;           // 결제 관련이면

    @Column(length = 200)
    private String description;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Builder
    public CoinTransaction(Long studentId, TransactionType type, Integer amount,
                           Integer balanceAfter, Long lessonId, Long paymentId,
                           String description) {
        this.studentId = studentId;
        this.type = type;
        this.amount = amount;
        this.balanceAfter = balanceAfter;
        this.lessonId = lessonId;
        this.paymentId = paymentId;
        this.description = description;
        this.createdAt = LocalDateTime.now();
    }
}