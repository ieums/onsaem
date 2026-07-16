package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.Subscription;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.List;

public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {

    Optional<Subscription> findByStudentIdAndActiveTrue(Long studentId);

    List<Subscription> findByStudentIdOrderByCreatedAtDesc(Long studentId);

    /** 기간이 끝난(endDate ≤ 기준일) 활성 구독 — 만료 스케줄러용. */
    List<Subscription> findByActiveTrueAndEndDateLessThanEqual(LocalDate date);

    /** 관리자 구독 목록 — 최신순 페이지. */
    Page<Subscription> findAllByOrderByCreatedAtDesc(Pageable pageable);
}