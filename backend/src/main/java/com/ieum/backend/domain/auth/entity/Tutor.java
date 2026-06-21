package com.ieum.backend.domain.auth.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 강사 계정. 인증 공통 필드(Account) + 강사 도메인 필드.
 * 등급(grade)·평점·집계는 결제/매칭/리뷰 도메인이 참조한다.
 */
@Entity
@Table(name = "tutor", uniqueConstraints = {
        @UniqueConstraint(name = "uk_tutor_provider", columnNames = {"provider", "provider_user_id"})
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Tutor extends Account {

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TutorGrade grade;

    @Column(columnDefinition = "TEXT")
    private String bio;

    @Column(length = 100)
    private String school;

    @Column(length = 100)
    private String major;

    @Enumerated(EnumType.STRING)
    @Column(name = "verification_status", nullable = false, length = 20)
    private VerificationStatus verificationStatus;

    /** 평점 평균 0.0~5.0. 리뷰 없으면 null */
    @Column(name = "rating_avg", precision = 2, scale = 1)
    private BigDecimal ratingAvg;

    @Column(name = "review_count", nullable = false)
    private int reviewCount;

    @Column(name = "lesson_count", nullable = false)
    private int lessonCount;

    @Builder
    private Tutor(String name, String email, String password,
                  AuthProvider provider, String providerUserId, String profileImageUrl,
                  String bio, String school, String major) {
        super(name, email, password, provider, providerUserId, profileImageUrl);
        this.bio = bio;
        this.school = school;
        this.major = major;
        this.grade = TutorGrade.ROOKIE;
        this.verificationStatus = VerificationStatus.PENDING;
        this.reviewCount = 0;
        this.lessonCount = 0;
    }
}