package com.ieum.backend.domain.payment.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "coin_packages")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CoinPackage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(nullable = false)
    private Integer price;

    @Column(nullable = false)
    private Integer coinAmount;

    @Column(nullable = false)
    private Integer bonusAmount;

    @Column(nullable = false)
    private Boolean active;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @Builder
    public CoinPackage(String name, Integer price, Integer coinAmount,
                       Integer bonusAmount) {
        this.name = name;
        this.price = price;
        this.coinAmount = coinAmount;
        this.bonusAmount = bonusAmount != null ? bonusAmount : 0;
        this.active = true;
        this.createdAt = LocalDateTime.now();
    }

    // 총 지급 코인 (기본 + 보너스)
    public int getTotalCoin() {
        return this.coinAmount + this.bonusAmount;
    }

    // 가격 변경
    public void updatePrice(Integer price) {
        this.price = price;
        this.updatedAt = LocalDateTime.now();
    }

    // 보너스 변경
    public void updateBonus(Integer bonusAmount) {
        this.bonusAmount = bonusAmount;
        this.updatedAt = LocalDateTime.now();
    }

    // 판매 중지
    public void deactivate() {
        this.active = false;
        this.updatedAt = LocalDateTime.now();
    }

    // 판매 재개
    public void activate() {
        this.active = true;
        this.updatedAt = LocalDateTime.now();
    }
}