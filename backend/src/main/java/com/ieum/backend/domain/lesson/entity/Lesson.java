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

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    public Lesson(String channelName) {
        this.channelName = channelName;
    }

    public Lesson(String channelName, Long tutorId, Long studentId) {
        this.channelName = channelName;
        this.tutorId = tutorId;
        this.studentId = studentId;
    }

    /** 수업 시작: 상태를 ACTIVE로, startedAt 기록 */
    public void start() {
        this.status = LessonStatus.ACTIVE;
        this.startedAt = LocalDateTime.now();
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
        WAITING, ACTIVE, COMPLETED
    }

    @Column(name = "problem_id")
    private Long problemId;

}
