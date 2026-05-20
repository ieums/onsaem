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

    @Column(name = "teacher_id")
    private Long teacherId;

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

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    public Lesson(String channelName) {
        this.channelName = channelName;
    }

    public void start() {
        this.status = LessonStatus.ACTIVE;
        this.startedAt = LocalDateTime.now();
    }

    public void complete(String recordingUrl) {
        this.status = LessonStatus.COMPLETED;
        this.endedAt = LocalDateTime.now();
        this.recordingUrl = recordingUrl;
    }

    public enum LessonStatus {
        WAITING, ACTIVE, COMPLETED
    }
}
