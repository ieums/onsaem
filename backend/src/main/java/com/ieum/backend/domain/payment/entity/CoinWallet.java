package com.ieum.backend.domain.payment.entity;

import jakarta.persistence.*;
import lombok.*;

import com.ieum.backend.global.exception.BusinessException;

import java.time.LocalDateTime;

@Entity
@Table(name = "coin_wallets")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CoinWallet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private Long studentId;

    @Column(nullable = false)
    private Integer balance;

    @Column(nullable = false)
    private Integer availableBalance;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @Builder
    public CoinWallet(Long studentId) {
        this.studentId = studentId;
        this.balance = 0;
        this.availableBalance = 0;
        this.createdAt = LocalDateTime.now();
    }

    // 코인 충전
    public void charge(int amount) {
        this.balance += amount;
        this.availableBalance += amount;
        this.updatedAt = LocalDateTime.now();
    }

    public void subtract(int amount) {
        this.balance -= amount;
        this.availableBalance -= amount;
    }

    // 코인 홀드 (강의 시작 시)
    public void hold(int amount) {
        if (this.availableBalance < amount) {
            throw BusinessException.badRequest("코인이 부족합니다. 잔액: " + this.availableBalance);
        }
        this.availableBalance -= amount;
        this.updatedAt = LocalDateTime.now();
    }

    // 홀드 확정 (강의 종료 시)
    public void confirmDeduct(int amount) {
        this.balance -= amount;
        this.updatedAt = LocalDateTime.now();
    }

    // 홀드 해제 (강의 취소 시)
    public void releaseHold(int amount) {
        this.availableBalance += amount;
        this.updatedAt = LocalDateTime.now();
    }

    // AI 사용 (즉시 차감)
    public void useForAi(int amount) {
        if (this.availableBalance < amount) { //race condition: check-then-act
            throw BusinessException.badRequest("코인이 부족합니다. 잔액: " + this.availableBalance);
        }
        this.balance -= amount;
        this.availableBalance -= amount;
        this.updatedAt = LocalDateTime.now();
    }
}