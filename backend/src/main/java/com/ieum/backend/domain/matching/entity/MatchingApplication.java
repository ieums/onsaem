package com.ieum.backend.domain.matching.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "matching_applications")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MatchingApplication {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long problemId;

    @Column(nullable = false)
    private Long tutorId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ApplicationStatus status;

    @Column(nullable = false)
    private LocalDateTime appliedAt;

    private LocalDateTime respondedAt;

    @Builder
    public MatchingApplication(Long problemId, Long tutorId) {
        this.problemId = problemId;
        this.tutorId = tutorId;
        this.status = ApplicationStatus.PENDING;
        this.appliedAt = LocalDateTime.now();
    }

    public void accept() {
        this.status = ApplicationStatus.ACCEPTED;
        this.respondedAt = LocalDateTime.now();
    }

    public void reject() {
        this.status = ApplicationStatus.REJECTED;
        this.respondedAt = LocalDateTime.now();
    }

    public void markUnavailable() {
        this.status = ApplicationStatus.UNAVAILABLE;
    }

    public void restorePending() {
        this.status = ApplicationStatus.PENDING;
    }

    public void expire() {
        this.status = ApplicationStatus.EXPIRED;
    }
}
