package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.CoinTransaction;
import com.ieum.backend.domain.payment.entity.enums.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CoinTransactionRepository extends JpaRepository<CoinTransaction, Long> {

    List<CoinTransaction> findByStudentIdOrderByCreatedAtDesc(Long studentId);

    List<CoinTransaction> findByStudentIdAndTypeOrderByCreatedAtDesc(Long studentId, TransactionType type);

    List<CoinTransaction> findByLessonIdAndType(Long lessonId, TransactionType type);

    // ── 관리자 콘솔(코인 거래 내역) ──
    List<CoinTransaction> findTop300ByOrderByCreatedAtDesc();

    /** 관리자 코인 거래 목록 — 페이지 슬라이스(최신순). */
    org.springframework.data.domain.Page<CoinTransaction> findAllByOrderByCreatedAtDesc(
            org.springframework.data.domain.Pageable pageable);
}