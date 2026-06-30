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
import java.util.HashSet;
import java.util.Set;

/**
 * 신고 (양방향: 학생↔강사). 강의 종료 후 상대/콘텐츠를 신고.
 * v1은 접수(PENDING)까지만. 운영자 처리(상태변경)는 추후.
 *
 * 대상당 1건: 같은 신고자가 같은 대상을 중복 신고하는 것을 UNIQUE로 차단.
 * 사유는 한 건에 여러 개 선택 가능(체크박스) → Set으로 보관.
 */
@Entity
@Table(
        name = "reports",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_reports_dedup",
                columnNames = {"reporter_id", "target_type", "target_id"}
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

    /** 신고 사유 (한 건에 여러 개 선택 가능) */
    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "report_reasons",
            joinColumns = @JoinColumn(name = "report_id")
    )
    @Enumerated(EnumType.STRING)
    @Column(name = "reason", nullable = false, length = 20)
    private Set<ReportReason> reasons = new HashSet<>();

    @Column(length = MAX_DESCRIPTION_LENGTH)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ReportStatus status;

    // ── 운영자 처리용 (v1 미사용, 추후) ──
    @Column(name = "admin_memo", length = MAX_DESCRIPTION_LENGTH)
    private String adminMemo;

    /** 관리자가 신고자에게 보내는 답변(신고자 '내 신고 내역'에 노출). adminMemo(내부용)와 구분. */
    @Column(name = "admin_reply", length = MAX_DESCRIPTION_LENGTH)
    private String adminReply;

    @Column(name = "handled_by")
    private Long handledBy;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime handledAt;

    @Builder
    public Report(Long reporterId, ReporterType reporterType,
                  ReportTargetType targetType, Long targetId, Long lessonId,
                  Set<ReportReason> reasons, String description) {
        this.reporterId = reporterId;
        this.reporterType = reporterType;
        this.targetType = targetType;
        this.targetId = targetId;
        this.lessonId = lessonId;
        this.reasons = (reasons != null) ? new HashSet<>(reasons) : new HashSet<>();
        this.description = description;
        this.status = ReportStatus.PENDING;
        this.createdAt = LocalDateTime.now();
    }

    // ── 운영자 처리(상태 전이) — 누가 처리했는지(handledBy)와 처리 시각을 함께 기록 ──

    /** 상태를 직접 지정해 전이하며 처리자/시각을 남긴다(감사용). */
    private void transitionTo(ReportStatus next, Long adminId) {
        this.status = next;
        this.handledBy = adminId;
        this.handledAt = LocalDateTime.now();
    }

    /** 검토중으로 변경 (PENDING → REVIEWING). */
    public void markReviewing(Long adminId) {
        transitionTo(ReportStatus.REVIEWING, adminId);
    }

    /** 처리완료=정상수업 확인(신고 무효) → RESOLVED. 출금 보류 해제됨. */
    public void resolve(Long adminId) {
        transitionTo(ReportStatus.RESOLVED, adminId);
    }

    /** 반려(신고 무효) → REJECTED. 출금 보류 해제됨. */
    public void reject(Long adminId) {
        transitionTo(ReportStatus.REJECTED, adminId);
    }

    /**
     * 신고 인정(uphold) → RESOLVED로 마감.
     * 별도 UPHELD 상태는 없으므로 처리완료(RESOLVED)로 마감하고,
     * 환불·정산 취소 등 부수효과는 서비스가 수행한다.
     */
    public void uphold(Long adminId) {
        transitionTo(ReportStatus.RESOLVED, adminId);
    }

    /** 관리자 답변 작성 — 신고자에게 보일 답변을 저장하고 처리자/시각을 남긴다(상태는 그대로). */
    public void writeReply(String reply, Long adminId) {
        this.adminReply = reply;
        this.handledBy = adminId;
        this.handledAt = LocalDateTime.now();
    }
}
