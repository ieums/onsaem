package com.ieum.backend.domain.lesson.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "lessons")
@Getter
@NoArgsConstructor
public class Lesson {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "channel_name", nullable = false, length = 100)
    private String channelName;

    @Column(name = "tutor_id")
    private Long tutorId;

    @Column(name = "student_id")
    private Long studentId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LessonStatus status = LessonStatus.WAITING;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;

    @Column(name = "recording_url", length = 500)
    private String recordingUrl;

    /** Agora Cloud Recording 리소스 ID (녹화 중지 시 필요) */
    @Column(name = "resource_id", length = 500)
    private String resourceId;

    /** Agora Cloud Recording SID (녹화 중지 시 필요) */
    @Column(name = "recording_sid", length = 500)
    private String recordingSid;

    /** 강의에 묶인(hold) 코인 비용. null이면 과금 미적용 강의 */
    @Column(name = "coin_cost")
    private Integer coinCost;

    /** 강의 종료 예정 시각 (시작 + 기본 30분). 표시·검증용 */
    @Column(name = "ends_at")
    private LocalDateTime endsAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    public Lesson(String channelName) {
        this.channelName = channelName;
    }

    /** 수업 시작: 상태를 ACTIVE로, startedAt 기록 */
    public void start() {
        this.status = LessonStatus.ACTIVE;
        this.startedAt = LocalDateTime.now();
    }

    /**
     * 과금 강의 시작: 학생·튜터·비용·종료예정시각을 함께 확정하고 ACTIVE로.
     * 코인 old는 호출자(LessonService)가 같은 트랜잭션에서 수행한다.
     */
    public void startBilling(Long studentId, Long tutorId, int coinCost, LocalDateTime endsAt) {
        this.studentId = studentId;
        this.tutorId = tutorId;
        this.coinCost = coinCost;
        this.endsAt = endsAt;
        this.status = LessonStatus.ACTIVE;
        this.startedAt = LocalDateTime.now();
    }

    /**
     * 강의 연장: 종료예정시각을 늘리고 묶인 비용을 누적한다.
     * 추가 코인 hold는 호출자(LessonService)가 같은 트랜잭션에서 수행.
     */
    public void extend(int minutes, int extensionCost) {
        this.endsAt = this.endsAt.plusMinutes(minutes);
        this.coinCost += extensionCost;
    }

    /** 강의 취소 (불성립). 묶인 코인 반환은 호출자가 수행 */
    public void cancel() {
        this.status = LessonStatus.CANCELED;
        this.endedAt = LocalDateTime.now();
    }

    /** 과금 대상 강의인지 (시작 시 코인이 묶였는지) */
    public boolean isBillable() {
        return this.coinCost != null;
    }

    /**
     * 수업 완료: 상태를 COMPLETED로, endedAt 기록
     * recordingUrl이 null이면 기존 값 유지 (stopRecording에서 미리 저장된 URL 보존)
     */
    public void complete(String recordingUrl) {
        this.status = LessonStatus.COMPLETED;
        this.endedAt = LocalDateTime.now();
        if (recordingUrl != null) {
            this.recordingUrl = recordingUrl;
        }
    }

    /** 녹화 시작 시 리소스 정보 저장 */
    public void setRecordingInfo(String resourceId, String recordingSid) {
        this.resourceId = resourceId;
        this.recordingSid = recordingSid;
    }

    /** 녹화 종료 후 파일 URL 저장 */
    public void setRecordingUrl(String recordingUrl) {
        this.recordingUrl = recordingUrl;
    }

    public enum LessonStatus {
        WAITING, ACTIVE, COMPLETED, CANCELED
    }
}
