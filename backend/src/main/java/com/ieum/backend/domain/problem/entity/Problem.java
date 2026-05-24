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
    private String userDescription;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime resolvedAt;

    @Builder
    public Problem(Long studentId, List<String> imageUrls, String extractedText,
                   String summary, Subject subject, String primaryType,
                   String secondaryType, Difficulty difficulty,
                   Integer totalDifficultyScore, ExamType examType,
                   String userDescription) {
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
        this.userDescription = userDescription;
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
}