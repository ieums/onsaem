package com.ieum.backend.domain.report.repository;

import com.ieum.backend.domain.report.entity.Report;
import com.ieum.backend.domain.report.entity.enums.ReportStatus;
import com.ieum.backend.domain.report.entity.enums.ReportTargetType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface ReportRepository extends JpaRepository<Report, Long> {

    /** 대상당 1건 — 같은 신고자가 같은 대상을 이미 신고했는지 */
    boolean existsByReporterIdAndTargetTypeAndTargetId(
            Long reporterId, ReportTargetType targetType, Long targetId);

    /** 내가 접수한 신고 목록 — 마이페이지 '내 신고 내역'. */
    List<Report> findByReporterIdOrderByCreatedAtDesc(Long reporterId);

    /** 그 강의에 열린(처리 전) 신고가 있는지 — 정산/복습 보류 게이팅. */
    boolean existsByLessonIdAndStatusIn(Long lessonId, Collection<ReportStatus> statuses);

    /** 주어진 강의들 중 '열린 신고'가 있는 강의 id만 한 번에 — 정산 목록/일괄출금 N+1 제거용. */
    @Query("select distinct r.lessonId from Report r "
            + "where r.lessonId in :lessonIds and r.status in :statuses")
    List<Long> findLessonIdsWithStatusIn(@Param("lessonIds") Collection<Long> lessonIds,
                                         @Param("statuses") Collection<ReportStatus> statuses);
}
