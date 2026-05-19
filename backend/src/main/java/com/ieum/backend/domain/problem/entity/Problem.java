package com.ieum.backend.domain.problem.entity;

import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

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

    @Column(nullable = false, length = 500)
    private String imageUrl;

    @Column(columnDefinition = "TEXT")
    private String extractedText;

    @Column(length = 300)
    private String summary;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Subject subject;

    @Column(length = 100)
    private String primaryType; //1차 유형(미적분, 수1)

    @Column(length = 100)
    private String secondaryType; //2차 유형

    @Column(length = 10)
    private String grade;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private Difficulty difficulty;

    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    private ExamType examType;

    // 난이도 종합 점수
    private Integer totalDifficultyScore;

    // 매칭 상태
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ProblemStatus status;

    @Column(length = 500)
    private String studentDescription;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime resolvedAt;

    @Builder
    public Problem(Long studentId, String imageUrl, String extractedText, String summary,
                   Subject subject, String primaryType, String secondaryType,
                   String grade, Difficulty difficulty, Integer totalDifficultyScore,
                   ExamType examType, String studentDescription) {
        this.studentId = studentId;
        this.imageUrl = imageUrl;
        this.extractedText = extractedText;
        this.summary = summary;
        this.subject = subject;
        this.primaryType = primaryType;
        this.secondaryType = secondaryType;
        this.grade = grade;
        this.difficulty = difficulty;
        this.totalDifficultyScore = totalDifficultyScore;
        this.examType = examType;
        this.studentDescription = studentDescription;
        this.status = ProblemStatus.PENDING;
        this.createdAt = LocalDateTime.now();
    }

    public void match() {
        this.status = ProblemStatus.MATCHED;
    }

    public void resolve() {
        this.status = ProblemStatus.RESOLVED;
        this.resolvedAt = LocalDateTime.now();
    }

    public void cancel() {
        this.status = ProblemStatus.CANCELED;
    }

    public void updateClassification(Subject subject, String primaryType,
                                     String secondaryType, Difficulty difficulty,
                                     ExamType examType) {
        this.subject = subject;
        this.primaryType = primaryType;
        this.secondaryType = secondaryType;
        this.difficulty = difficulty;
        if (examType != null) this.examType = examType;
    }
}