package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.CoinWallet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CoinWalletRepository extends JpaRepository<CoinWallet, Long> {

    Optional<CoinWallet> findByStudentId(Long studentId);
}