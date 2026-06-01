package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.Settlement;
import com.ieum.backend.domain.payment.entity.enums.SettlementStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SettlementRepository extends JpaRepository<Settlement, Long> {

    List<Settlement> findByTutorIdOrderByCreatedAtDesc(Long tutorId);

    List<Settlement> findByTutorIdAndStatus(Long tutorId, SettlementStatus status);

    List<Settlement> findByStatus(SettlementStatus status);
}