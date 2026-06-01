package com.ieum.backend.domain.user.entity;

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
 * AI 튜터 챗봇 세션
 * 학생이 특정 문제(problem)에 대해 AI 튜터와 나누는 하나의 대화 단위
 * student_id, problem_id 는 각각 다른 팀원이 소유한 도메인(student, problems)을
 * 가리키지만, 코드가 그 엔티티에 묶이지 않도록 JPA 연관관계 대신 단순 Long 컬럼으로 둠
 */
@Entity
@Table(name = "ai_tutor_session")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AiTutorSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 세션을 시작한 학생 (student.id 참조) */
    @Column(name = "student_id", nullable = false)
    private Long studentId;

    /** 대화 대상 문제 (problems.id 참조) */
    @Column(name = "problem_id", nullable = false)
    private Long problemId;

    /** 세션 목록 화면에 표시할 제목 */
    @Column(length = 255)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AiTutorSessionStatus status;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /** 마지막 메시지가 오간 시각 (최근순 정렬용) */
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "session", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AiTutorMessage> messages = new ArrayList<>();

    @Builder
    private AiTutorSession(Long studentId, Long problemId, String title) {
        this.studentId = studentId;
        this.problemId = problemId;
        this.title = title;
        this.status = AiTutorSessionStatus.ACTIVE;
    }

    /** 양방향 연관관계 편의 메서드 — 메시지를 세션에 추가 */
    public void addMessage(AiTutorMessage message) {
        this.messages.add(message);
        message.assignSession(this);
    }

    /** 세션을 종료 상태로 전환 */
    public void close() {
        this.status = AiTutorSessionStatus.CLOSED;
    }

    /** 세션 활동(메시지 송수신) 시 호출 — updatedAt 갱신해서 목록 최근순 정렬에 반영 */
    public void touch() {
        this.updatedAt = LocalDateTime.now();
    }
}
