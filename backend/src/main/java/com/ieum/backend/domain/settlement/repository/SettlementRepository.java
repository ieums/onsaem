package com.ieum.backend.domain.settlement.repository;

import com.ieum.backend.domain.settlement.entity.Settlement;
import com.ieum.backend.domain.settlement.entity.enums.SettlementStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface SettlementRepository extends JpaRepository<Settlement, Long> {

    // 강사별 정산 내역 (최신순)
    List<Settlement> findByTutorIdOrderByCreatedAtDesc(Long tutorId);

    // 강사별 + 상태별 조회
    List<Settlement> findByTutorIdAndStatusOrderByCreatedAtDesc(Long tutorId, SettlementStatus status);

    // 강의별 정산 (강의 1건당 정산 1건이어야 함 - 중복 방지용)
    Optional<Settlement> findByLessonId(Long lessonId);

    /** 강사 정산 요약을 DB에서 한 번에 집계 (전체 로드 후 합산 대신) */
    @Query("""
            select coalesce(sum(s.tutorAmount), 0) as totalAmount,
                   coalesce(sum(case when s.status = com.ieum.backend.domain.settlement.entity.enums.SettlementStatus.TRANSFERRED
                                     then s.tutorAmount else 0 end), 0) as transferredAmount,
                   coalesce(sum(case when s.status in (com.ieum.backend.domain.settlement.entity.enums.SettlementStatus.CALCULATED,
                                                       com.ieum.backend.domain.settlement.entity.enums.SettlementStatus.PENDING)
                                     then s.tutorAmount else 0 end), 0) as pendingAmount,
                   count(s) as settlementCount
            from Settlement s
            where s.tutorId = :tutorId
              and s.status <> com.ieum.backend.domain.settlement.entity.enums.SettlementStatus.CANCELED
            """)
    SettlementAggregate aggregateByTutor(Long tutorId);

    /** aggregateByTutor 결과 매핑용 프로젝션 */
    interface SettlementAggregate {
        Long getTotalAmount();
        Long getTransferredAmount();
        Long getPendingAmount();
        Long getSettlementCount();
    }

    // ── 관리자 콘솔용 ──

    /** 전체 정산(최신순) — 관리자 정산 목록(상태 필터 없음). */
    List<Settlement> findAllByOrderByCreatedAtDesc();

    /** 상태별 정산(최신순) — 관리자 정산 목록 필터. */
    List<Settlement> findByStatusOrderByCreatedAtDesc(SettlementStatus status);

    /** 관리자 정산 목록(페이지) — 전체/상태별. */
    org.springframework.data.domain.Page<Settlement> findAllByOrderByCreatedAtDesc(
            org.springframework.data.domain.Pageable pageable);

    org.springframework.data.domain.Page<Settlement> findByStatusOrderByCreatedAtDesc(
            SettlementStatus status, org.springframework.data.domain.Pageable pageable);

    /** 상태별 합계/건수 — 대시보드 집계. */
    @Query("""
            select count(s) as cnt, coalesce(sum(s.tutorAmount), 0) as amount
            from Settlement s
            where s.status = :status
            """)
    SettlementStatusAggregate aggregateByStatus(SettlementStatus status);

    /** aggregateByStatus 결과 매핑용 프로젝션 */
    interface SettlementStatusAggregate {
        Long getCnt();
        Long getAmount();
    }
}