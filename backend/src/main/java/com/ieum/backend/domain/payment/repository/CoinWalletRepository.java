package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.CoinWallet;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;

public interface CoinWalletRepository extends JpaRepository<CoinWallet, Long> {

    Optional<CoinWallet> findByStudentId(Long studentId);

    /**
     * 잔액 변경용 — 지갑 행에 쓰기 락을 걸어 동시 충전/홀드/차감을 직렬화.
     * check-then-act(availableBalance 검사 후 차감)로 인한 음수 잔액을 방지한다.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from CoinWallet w where w.studentId = :studentId")
    Optional<CoinWallet> findByStudentIdForUpdate(Long studentId);
}