package com.ieum.backend.domain.report.dto.response;

import com.ieum.backend.domain.report.entity.Report;
import com.ieum.backend.domain.report.entity.enums.ReportReason;
import com.ieum.backend.domain.report.entity.enums.ReportStatus;
import com.ieum.backend.domain.report.entity.enums.ReportTargetType;
import com.ieum.backend.domain.report.entity.enums.ReporterType;

import java.time.LocalDateTime;
import java.util.Set;

public record ReportResponse(
        Long id,
        Long reporterId,
        ReporterType reporterType,
        ReportTargetType targetType,
        Long targetId,
        Long lessonId,
        Set<ReportReason> reasons,
        String description,
        ReportStatus status,
        LocalDateTime createdAt
) {
    public static ReportResponse from(Report r) {
        return new ReportResponse(
                r.getId(), r.getReporterId(), r.getReporterType(),
                r.getTargetType(), r.getTargetId(), r.getLessonId(),
                r.getReasons(), r.getDescription(), r.getStatus(), r.getCreatedAt()
        );
    }
}
