package com.ieum.backend.domain.settlement.entity;

import com.ieum.backend.domain.settlement.entity.enums.SettlementStatus;
import com.ieum.backend.global.exception.BusinessException;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "settlements",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_settlements_lesson_id",
                columnNames = "lesson_id"
        )
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Settlement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long tutorId;

    @Column(name = "lesson_id", nullable = false)
    private Long lessonId;

    @Column(nullable = false)
    private Integer totalCoin;          // 총 코인: 학생이 제출한 것

    @Column(nullable = false)
    private Integer platformFeeCoin;    // 플랫폼 수수료 코인

    @Column(nullable = false)
    private Integer tutorCoin;          // 강사 몫 코인

    @Column(nullable = false)
    private Integer tutorAmount;        // 강사 정산금 현금금액

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SettlementStatus status;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime transferredAt;  // 실제 송금 시각

    @Builder
    public Settlement(Long tutorId, Long lessonId, Integer totalCoin,
                      Integer platformFeeCoin, Integer tutorCoin, Integer tutorAmount) {
        this.tutorId = tutorId;
        this.lessonId = lessonId;
        this.totalCoin = totalCoin;
        this.platformFeeCoin = platformFeeCoin;
        this.tutorCoin = tutorCoin;
        this.tutorAmount = tutorAmount;
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

    /**
     * 정산 취소(롤백) — 강의 환불/취소 시. 이미 송금 완료(TRANSFERRED)된 건은
     * 실제 돈이 나갔으므로 자동 롤백 불가(별도 회수 절차 필요).
     */
    public void cancel() {
        if (this.status == SettlementStatus.TRANSFERRED) {
            throw BusinessException.conflict(
                    "이미 송금 완료된 정산은 취소할 수 없습니다. settlementId: " + this.id);
        }
        this.status = SettlementStatus.CANCELED;
    }
}