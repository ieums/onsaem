package com.ieum.backend.domain.report.entity;

import com.ieum.backend.domain.report.entity.enums.ReportReason;
import com.ieum.backend.domain.report.entity.enums.ReportStatus;
import com.ieum.backend.domain.report.entity.enums.ReportTargetType;
import com.ieum.backend.domain.report.entity.enums.ReporterType;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 신고 (양방향: 학생↔강사). 강의 종료 후 상대/콘텐츠를 신고.
 * v1은 접수(PENDING)까지만. 운영자 처리(상태변경)는 추후.
 * 같은 신고자가 같은 대상·사유로 중복 신고하는 것을 UNIQUE로 차단.
 */
@Entity
@Table(
        name = "reports",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_reports_dedup",
                columnNames = {"reporter_id", "target_type", "target_id", "reason"}
        )
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Report {

    public static final int MAX_DESCRIPTION_LENGTH = 1000;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "reporter_id", nullable = false)
    private Long reporterId;

    @Enumerated(EnumType.STRING)
    @Column(name = "reporter_type", nullable = false, length = 10)
    private ReporterType reporterType;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", nullable = false, length = 10)
    private ReportTargetType targetType;

    @Column(name = "target_id", nullable = false)
    private Long targetId;

    /** 강의 종료 후 신고면 그 강의 (콘텐츠 신고 등은 null) */
    @Column(name = "lesson_id")
    private Long lessonId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ReportReason reason;

    @Column(length = MAX_DESCRIPTION_LENGTH)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ReportStatus status;

    // ── 운영자 처리용 (v1 미사용, 추후) ──
    @Column(name = "admin_memo", length = MAX_DESCRIPTION_LENGTH)
    private String adminMemo;

    @Column(name = "handled_by")
    private Long handledBy;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime handledAt;

    @Builder
    public Report(Long reporterId, ReporterType reporterType,
                  ReportTargetType targetType, Long targetId, Long lessonId,
                  ReportReason reason, String description) {
        this.reporterId = reporterId;
        this.reporterType = reporterType;
        this.targetType = targetType;
        this.targetId = targetId;
        this.lessonId = lessonId;
        this.reason = reason;
        this.description = description;
        this.status = ReportStatus.PENDING;
        this.createdAt = LocalDateTime.now();
    }
}
