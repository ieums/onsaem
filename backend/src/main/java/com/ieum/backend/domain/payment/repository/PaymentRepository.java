package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.Payment;
import com.ieum.backend.domain.payment.entity.enums.PaymentStatus;
import com.ieum.backend.domain.payment.entity.enums.PaymentTargetType;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findByMerchantId(String merchantId);

    /**
     * 결제 완료 처리용 — 결제 행에 쓰기 락을 걸어 동시 완료 요청 직렬화.
     * 두 번째 요청은 첫 트랜잭션 커밋까지 대기했다가 COMPLETED 상태를 읽어 멱등 반환한다.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Payment p where p.merchantId = :merchantId")
    Optional<Payment> findByMerchantIdForUpdate(String merchantId);

    /** 환불 처리용 — 결제 행에 쓰기 락을 걸어 동시 환불을 직렬화 */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Payment p where p.id = :id")
    Optional<Payment> findByIdForUpdate(Long id);

    List<Payment> findByStudentIdOrderByCreatedAtDesc(Long studentId);

    List<Payment> findByStudentIdAndTargetTypeOrderByCreatedAtDesc(
            Long studentId, PaymentTargetType targetType
    );

    List<Payment> findByStudentIdAndStatusOrderByCreatedAtDesc(Long studentId, PaymentStatus status);
}