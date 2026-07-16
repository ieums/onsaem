package com.ieum.backend.domain.lessonreview.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 강의 복습 AI 챗봇 세션
 * 학생이 특정 강의(lesson)에 대해 AI와 복습 대화를 나누는 단위
 * AiTutorSession과 동일 패턴 — student_id, lesson_id는 타 도메인 디커플링 위해 Long 컬럼
 */
@Entity
@Table(name = "lesson_review_session")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class LessonReviewSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "student_id", nullable = false)
    private Long studentId;

    @Column(name = "lesson_id", nullable = false)
    private Long lessonId;

    /** 세션 목록 화면에 표시할 제목 (강의 메타 기반 자동 생성) */
    @Column(length = 255)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LessonReviewSessionStatus status;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /** 마지막 메시지가 오간 시각 (최근순 정렬용 — touch()로 갱신) */
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "session", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<LessonReviewMessage> messages = new ArrayList<>();

    @Builder
    private LessonReviewSession(Long studentId, Long lessonId, String title) {
        this.studentId = studentId;
        this.lessonId = lessonId;
        this.title = title;
        this.status = LessonReviewSessionStatus.ACTIVE;
    }

    /** 양방향 연관관계 편의 메서드 */
    public void addMessage(LessonReviewMessage message) {
        this.messages.add(message);
        message.assignSession(this);
    }

    /** 세션을 종료 상태로 전환 */
    public void close() {
        this.status = LessonReviewSessionStatus.CLOSED;
    }

    /** 세션 활동(메시지 송수신) 시 호출 — updatedAt 갱신 */
    public void touch() {
        this.updatedAt = LocalDateTime.now();
    }
}