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
import java.time.LocalDate;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.JoinColumn;
import java.util.ArrayList;
import java.util.List;

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

    @Column(name = "experience_years")
    private Integer experienceYears;

    @Enumerated(EnumType.STRING)
    @Column(name = "education_status", length = 20)
    private EducationStatus educationStatus;

    @ElementCollection
    @CollectionTable(name = "tutor_subject", joinColumns = @JoinColumn(name = "tutor_id"))
    @Column(name = "subject", length = 50)
    private List<String> subjects = new ArrayList<>();

    @ElementCollection
    @CollectionTable(name = "tutor_lecture_style", joinColumns = @JoinColumn(name = "tutor_id"))
    @Column(name = "style", length = 50)
    private List<String> lectureStyles = new ArrayList<>();

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

    @Column(name = "is_available", nullable = false, columnDefinition = "TINYINT(1) DEFAULT 1")
    private boolean available = true;

    public void updateAvailability(boolean available) {
        this.available = available;
    }

    /** 강사 전용 프로필 수정 — null이 아닌 값만 갱신. */
    public void updateTutorProfile(String bio, String school, String major,
                                   List<String> subjects, EducationStatus educationStatus,
                                   Integer experienceYears) {
        if (bio != null) this.bio = bio;
        if (school != null) this.school = school;
        if (major != null) this.major = major;
        if (subjects != null) { this.subjects.clear(); this.subjects.addAll(subjects); }
        if (educationStatus != null) this.educationStatus = educationStatus;
        if (experienceYears != null) this.experienceYears = experienceYears;
    }

    @Builder
    private Tutor(String name, String email, String password,
                  AuthProvider provider, String providerUserId, String profileImageUrl,
                  LocalDate birthDate, String phone,
                  String bio, String school, String major,Integer experienceYears, EducationStatus educationStatus,
                  List<String> subjects, List<String> lectureStyles) {
        super(name, email, password, provider, providerUserId, profileImageUrl, birthDate, phone);
        this.bio = bio;
        this.school = school;
        this.major = major;
        this.experienceYears = experienceYears;
        this.educationStatus = educationStatus;
        this.subjects = subjects != null ? subjects : new ArrayList<>();
        this.lectureStyles = lectureStyles != null ? lectureStyles : new ArrayList<>();
        this.grade = TutorGrade.ROOKIE;
        this.verificationStatus = VerificationStatus.PENDING;
        this.reviewCount = 0;
        this.lessonCount = 0;
    }
}