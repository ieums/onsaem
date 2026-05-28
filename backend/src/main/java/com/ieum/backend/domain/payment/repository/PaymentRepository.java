package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.Payment;
import com.ieum.backend.domain.payment.entity.enums.PaymentStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findByMerchantId(String merchantId);

    List<Payment> findByStudentIdOrderByCreatedAtDesc(Long studentId);

    List<Payment> findByStudentIdAndStatusOrderByCreatedAtDesc(Long studentId, PaymentStatus status);
}