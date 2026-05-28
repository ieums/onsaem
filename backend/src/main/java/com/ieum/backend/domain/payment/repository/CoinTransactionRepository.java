package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.CoinTransaction;
import com.ieum.backend.domain.payment.entity.enums.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CoinTransactionRepository extends JpaRepository<CoinTransaction, Long> {

    List<CoinTransaction> findByStudentIdOrderByCreatedAtDesc(Long studentId);

    List<CoinTransaction> findByStudentIdAndTypeOrderByCreatedAtDesc(Long studentId, TransactionType type);

    List<CoinTransaction> findByLessonIdAndType(Long lessonId, TransactionType type);
}