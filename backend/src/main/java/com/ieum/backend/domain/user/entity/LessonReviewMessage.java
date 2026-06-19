package com.ieum.backend.domain.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 강의 복습 챗봇 세션 안에서 오간 메시지 한 건.
 * 학생(USER)과 AI(AI)가 주고받은 대화가 시간순으로 쌓임.
 */
@Entity
@Table(name = "lesson_review_message")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class LessonReviewMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "session_id", nullable = false)
    private LessonReviewSession session;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private LessonReviewMessageRole role;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Builder
    private LessonReviewMessage(LessonReviewSession session, LessonReviewMessageRole role, String content) {
        this.session = session;
        this.role = role;
        this.content = content;
    }

    /**
     * 세션 설정. {@link LessonReviewSession#addMessage(LessonReviewMessage)} 에서만 호출.
     */
    void assignSession(LessonReviewSession session) {
        this.session = session;
    }
}