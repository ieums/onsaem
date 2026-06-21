package com.ieum.backend.domain.report.repository;

import com.ieum.backend.domain.report.entity.Report;
import com.ieum.backend.domain.report.entity.enums.ReportReason;
import com.ieum.backend.domain.report.entity.enums.ReportTargetType;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportRepository extends JpaRepository<Report, Long> {

    boolean existsByReporterIdAndTargetTypeAndTargetIdAndReason(
            Long reporterId, ReportTargetType targetType, Long targetId, ReportReason reason);
}
