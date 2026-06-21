package com.ieum.backend.domain.lessonreview.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 강의 영상의 전사(STT) 결과 캐시.
 * 한 lesson당 한 행 (lesson_id UNIQUE).
 * Scheduler가 PENDING/FAILED 상태인 행을 찾아 Gemini File API로 처리.
 */
@Entity
@Table(
        name = "lesson_transcript",
        uniqueConstraints = @UniqueConstraint(name = "uk_lesson_transcript_lesson_id", columnNames = "lesson_id"),
        indexes = @Index(name = "idx_lesson_transcript_status", columnList = "status")
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class LessonTranscript {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "lesson_id", nullable = false)
    private Long lessonId;

    /** 강의 전체 전사 텍스트 (한국어, 발화자 구분 포함) */
    @Column(columnDefinition = "TEXT")
    private String transcript;

    /** 한 줄/문단 요약 (선택) */
    @Column(length = 500)
    private String summary;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LessonTranscriptStatus status;

    /** 실패 시 사유 (재시도 디버깅용) */
    @Column(name = "error_message", length = 500)
    private String errorMessage;

    /** 전사 처리 완료/실패 시각 */
    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // PDF 캐시 컬럼들
    @Enumerated(EnumType.STRING)
    @Column(name = "summary_pdf_status", length = 20)
    private LessonSummaryPdfStatus summaryPdfStatus;

    @Column(name = "summary_pdf_url", length = 500)
    private String summaryPdfUrl;

    @Column(name = "summary_pdf_error_message", length = 500)
    private String summaryPdfErrorMessage;

    @Column(name = "summary_pdf_generated_at")
    private LocalDateTime summaryPdfGeneratedAt;

    @Builder
    private LessonTranscript(Long lessonId) {
        this.lessonId = lessonId;
        this.status = LessonTranscriptStatus.PENDING;
    }


    /** PROCESSING 상태로 전환 — 전사 시작 시 */
    public void markProcessing() {
        this.status = LessonTranscriptStatus.PROCESSING;
        this.errorMessage = null;

    }

    /** COMPLETED 상태로 전환 — 전사 성공 시 */
    public void markCompleted(String transcript, String summary) {
        this.transcript = transcript;
        this.summary = summary;
        this.status = LessonTranscriptStatus.COMPLETED;
        this.errorMessage = null;
        this.processedAt = LocalDateTime.now();
    }

    /** FAILED 상태로 전환 — 전사 실패 시 (다음 폴링에서 재시도 가능) */
    public void markFailed(String errorMessage) {
        this.status = LessonTranscriptStatus.FAILED;
        this.errorMessage = errorMessage != null && errorMessage.length() > 500
                ? errorMessage.substring(0, 500)
                : errorMessage;
        this.processedAt = LocalDateTime.now();
    }

    /** PDF 처리 시작 표시 */
    public void markPdfProcessing() {
        this.summaryPdfStatus = LessonSummaryPdfStatus.PROCESSING;
        this.summaryPdfErrorMessage = null;
    }

    /** PDF 처리 완료 — S3 URL 저장 */
    public void markPdfCompleted(String s3Url) {
        this.summaryPdfStatus = LessonSummaryPdfStatus.COMPLETED;
        this.summaryPdfUrl = s3Url;
        this.summaryPdfErrorMessage = null;
        this.summaryPdfGeneratedAt = LocalDateTime.now();
    }

    /** PDF 처리 실패 */
    public void markPdfFailed(String errorMessage) {
        this.summaryPdfStatus = LessonSummaryPdfStatus.FAILED;
        this.summaryPdfErrorMessage = errorMessage != null && errorMessage.length() > 500
                ? errorMessage.substring(0, 500) : errorMessage;
        this.summaryPdfGeneratedAt = LocalDateTime.now();
    }

}