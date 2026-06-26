package com.ieum.backend.domain.problem.entity;

import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "problems")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Problem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long studentId;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "problem_images",
            joinColumns = @JoinColumn(name = "problem_id")
    )
    @Column(name = "image_url", length = 500)
    @OrderColumn(name = "page_order")
    private List<String> imageUrls = new ArrayList<>();

    @Column(columnDefinition = "TEXT")
    private String extractedText;

    @Column(length = 500)
    private String summary;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private Subject subject;

    @Column(length = 50)
    private String primaryType;

    @Column(length = 50)
    private String secondaryType;

    @Enumerated(EnumType.STRING)
    @Column(length = 10)
    private Difficulty difficulty;

    private Integer totalDifficultyScore;

    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    private ExamType examType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ProblemStatus status;

    @Column(columnDefinition = "TEXT")
    private String studentDescription;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime resolvedAt;

    private LocalDateTime searchDeadline;

    @Column(nullable = false)
    private boolean searching = false;

    @Column(nullable = false)
    private boolean expiringSoonNotified = false;

    @Builder
    public Problem(Long studentId, List<String> imageUrls, String extractedText,
                   String summary, Subject subject, String primaryType,
                   String secondaryType, Difficulty difficulty,
                   Integer totalDifficultyScore, ExamType examType,
                   String studentDescription) {
        this.studentId = studentId;
        this.imageUrls = imageUrls != null ? imageUrls : new ArrayList<>();
        this.extractedText = extractedText;
        this.summary = summary;
        this.subject = subject;
        this.primaryType = primaryType;
        this.secondaryType = secondaryType;
        this.difficulty = difficulty;
        this.totalDifficultyScore = totalDifficultyScore;
        this.examType = examType;
        this.studentDescription = studentDescription;
        this.status = ProblemStatus.PENDING;
        this.createdAt = LocalDateTime.now();
    }

    // 학생이 분류 수정
    public void updateClassification(Subject subject, String primaryType,
                                     String secondaryType, Difficulty difficulty,
                                     ExamType examType) {
        if (subject != null) this.subject = subject;
        if (primaryType != null) this.primaryType = primaryType;
        if (secondaryType != null) this.secondaryType = secondaryType;
        if (difficulty != null) this.difficulty = difficulty;
        if (examType != null) this.examType = examType;
    }

    // 문제 해결됨
    public void markResolved() {
        this.status = ProblemStatus.RESOLVED;
        this.resolvedAt = LocalDateTime.now();
    }

    // 문제 등록 취소
    public void cancel() {
        this.status = ProblemStatus.CANCELED;
    }

    public void startSearching(LocalDateTime deadline) {
        this.searching = true;
        this.searchDeadline = deadline;
    }

    public void extendDeadline(LocalDateTime newDeadline) {
        this.searchDeadline = newDeadline;
        this.searching = true;
        this.expiringSoonNotified = false;
    }

    public void markExpiringSoonNotified() {
        this.expiringSoonNotified = true;
    }

    public void matchTutor() {
        this.status = ProblemStatus.MATCHED;
        this.searching = false;
    }

    public void stopSearching() {
        this.searching = false;
    }

    /** 탐색 마감까지 강사 못 구함 → 만료 처리(상태 EXPIRED + 탐색 종료). */
    public void markExpired() {
        this.status = ProblemStatus.EXPIRED;
        this.searching = false;
    }

    /** 만료된 질문을 다시 탐색 대기로 되돌린다('다시 요청'). */
    public void reopen() {
        this.status = ProblemStatus.PENDING;
        this.expiringSoonNotified = false;
    }
}