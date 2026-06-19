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
 * AI 튜터 챗봇 세션 안에서 오간 메시지 한 건.
 * 학생(USER)과 AI 튜터(AI)가 주고받은 대화가 시간순으로 쌓인다.
 */
@Entity
@Table(name = "ai_tutor_message")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AiTutorMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 이 메시지가 속한 세션 */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "session_id", nullable = false)
    private AiTutorSession session;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private AiTutorMessageRole role;

    /** 메시지 본문 */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Builder
    private AiTutorMessage(AiTutorSession session, AiTutorMessageRole role, String content) {
        this.session = session;
        this.role = role;
        this.content = content;
    }

    /**
     * 세션을 설정한다. {@link AiTutorSession#addMessage(AiTutorMessage)} 에서만 호출하도록
     * 패키지 전용으로 제한해 양방향 연관관계의 일관성을 지킨다.
     */
    void assignSession(AiTutorSession session) {
        this.session = session;
    }
}
