package com.ieum.backend.domain.payment.entity;

import com.ieum.backend.domain.payment.entity.enums.SettlementStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "settlements")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Settlement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long tutorId;

    @Column(nullable = false)
    private Long lessonId;

    @Column(nullable = false)
    private Integer totalCoin;          // 총 코인 (학생이 낸 것)

    @Column(nullable = false)
    private Integer platformFeeCoin;    // 플랫폼 수수료 (20%)

    @Column(nullable = false)
    private Integer tutorCoin;          // 강사 몫 (80%)

    @Column(nullable = false)
    private Integer tutorAmount;        // 강사 정산금 (원)

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SettlementStatus status;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime transferredAt;  // 실제 송금 시각

    @Builder
    public Settlement(Long tutorId, Long lessonId, Integer totalCoin) {
        this.tutorId = tutorId;
        this.lessonId = lessonId;
        this.totalCoin = totalCoin;
        this.platformFeeCoin = (int) (totalCoin * 0.2);   // 20%
        this.tutorCoin = totalCoin - this.platformFeeCoin; // 80%
        this.tutorAmount = this.tutorCoin * 100;           // 1코인 = 100원
        this.status = SettlementStatus.CALCULATED;
        this.createdAt = LocalDateTime.now();
    }

    // 송금 대기로 변경 (정산일 도래)
    public void markPending() {
        this.status = SettlementStatus.PENDING;
    }

    // 송금 완료
    public void markTransferred() {
        this.status = SettlementStatus.TRANSFERRED;
        this.transferredAt = LocalDateTime.now();
    }

    // 송금 실패
    public void markFailed() {
        this.status = SettlementStatus.FAILED;
    }
}