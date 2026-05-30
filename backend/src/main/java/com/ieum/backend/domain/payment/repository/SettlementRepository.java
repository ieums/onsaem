package com.ieum.backend.domain.payment.repository;

import com.ieum.backend.domain.payment.entity.Settlement;
import com.ieum.backend.domain.payment.entity.enums.SettlementStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SettlementRepository extends JpaRepository<Settlement, Long> {

    // 강사별 정산 내역 (최신순)
    List<Settlement> findByTutorIdOrderByCreatedAtDesc(Long tutorId);

    // 강사별 + 상태별 조회
    List<Settlement> findByTutorIdAndStatusOrderByCreatedAtDesc(Long tutorId, SettlementStatus status);

    // 강의별 정산 (강의 1건당 정산 1건이어야 함 - 중복 방지용)
    Optional<Settlement> findByLessonId(Long lessonId);
}