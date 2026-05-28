package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {

    Optional<Subscription> findByStudentIdAndActiveTrue(Long studentId);

    List<Subscription> findByStudentIdOrderByCreatedAtDesc(Long studentId);
}