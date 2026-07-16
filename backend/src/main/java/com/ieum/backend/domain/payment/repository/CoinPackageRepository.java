package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.CoinPackage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CoinPackageRepository extends JpaRepository<CoinPackage, Long> {

    List<CoinPackage> findByActiveTrueOrderByPriceAsc();
}