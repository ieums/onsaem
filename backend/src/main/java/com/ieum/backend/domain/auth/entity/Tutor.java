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
import com.ieum.backend.domain.auth.policy.TutorGradePolicy;

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

    @Enumerated(EnumType.STRING)
    @Column(name = "verification_status", nullable = false, length = 20)
    private VerificationStatus verificationStatus;

    /** 학력 증빙 서류 S3 URL. 선택 항목이라 nullable. 검토는 verificationStatus로. */
    @Column(name = "verification_document_url", length = 512)
    private String verificationDocumentUrl;

    /** 평점 평균 0.0~5.0. 리뷰 없으면 null */
    @Column(name = "rating_avg", precision = 2, scale = 1)
    private BigDecimal ratingAvg;

    @Column(name = "review_count", nullable = false)
    private int reviewCount;

    @Column(name = "lesson_count", nullable = false)
    private int lessonCount;

    @Column(name = "is_available", nullable = false, columnDefinition = "TINYINT(1) DEFAULT 1")
    private boolean available = true;

    // ── 정산 입금 계좌 (마이페이지 > 정산 계좌 관리) ──
    @Column(name = "settlement_bank", length = 30)
    private String settlementBank;

    @Column(name = "settlement_account", length = 50)
    private String settlementAccount;

    @Column(name = "settlement_holder", length = 50)
    private String settlementHolder;

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

    /** 정산 계좌 등록·수정 */
    public void updateSettlementAccount(String bank, String account, String holder) {
        this.settlementBank = bank;
        this.settlementAccount = account;
        this.settlementHolder = holder;
    }

    /** 출금 가능 여부 — 은행/계좌번호/예금주가 모두 등록돼 있어야 한다. */
    public boolean hasSettlementAccount() {
        return settlementBank != null && !settlementBank.isBlank()
                && settlementAccount != null && !settlementAccount.isBlank()
                && settlementHolder != null && !settlementHolder.isBlank();

    }

    /** 수업 완료 1건 반영 → 실적 누적 + 등급 재평가 */
    public void recordLessonCompleted() {
        this.lessonCount++;
        refreshGrade();
    }

    /** 리뷰 평균·개수 갱신 → 등급 재평가 */
    public void applyRating(BigDecimal ratingAvg, int reviewCount) {
        this.ratingAvg = ratingAvg;
        this.reviewCount = reviewCount;
        refreshGrade();
    }

    /** 경력+실적 기준 등급 재산정 — 강등 없이 상향만. */
    private void refreshGrade() {
        TutorGrade target =
                TutorGradePolicy.evaluate(experienceYears, lessonCount, ratingAvg);
        if (target.ordinal() > grade.ordinal()) {
            this.grade = target;
        }
    }


    @Builder
    private Tutor(String name, String email, String password,
                  AuthProvider provider, String providerUserId, String profileImageUrl,
                  LocalDate birthDate, String phone,
                  String bio, String school, String major,Integer experienceYears, EducationStatus educationStatus,
                  List<String> subjects, String verificationDocumentUrl) {
        super(name, email, password, provider, providerUserId, profileImageUrl, birthDate, phone);
        this.bio = bio;
        this.school = school;
        this.major = major;
        this.experienceYears = experienceYears;
        this.educationStatus = educationStatus;
        this.subjects = subjects != null ? subjects : new ArrayList<>();
        this.grade = TutorGradePolicy.initialGrade(experienceYears);
        this.verificationStatus = VerificationStatus.PENDING;
        this.verificationDocumentUrl = verificationDocumentUrl;
        this.reviewCount = 0;
        this.lessonCount = 0;
    }
}