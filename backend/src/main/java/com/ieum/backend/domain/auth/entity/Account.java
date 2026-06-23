package com.ieum.backend.domain.auth.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDate;

import java.time.LocalDateTime;

/**
 * 학생/강사 공통 인증·계정 필드. 테이블로 생성되지 않고(@MappedSuperclass),
 * 상속하는 Student/Tutor 각 테이블에 컬럼으로 펼쳐진다.
 * (provider, provider_user_id) 유니크 제약은 자식 @Table 에서 건다.
 */
@MappedSuperclass
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public abstract class Account {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 탈퇴 시 파기되므로 DB 상 nullable. 정상 가입의 필수성은 가입 DTO(@NotBlank)로 보장 */
    @Column(length = 50)
    private String name;

    @Column(length = 255)
    private String email;

    /** BCrypt 해시. 소셜 로그인 계정은 null */
    @Column(length = 255)
    private String password;

    @Column(name = "profile_image_url", length = 500)
    private String profileImageUrl;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(length = 20)
    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AuthProvider provider;

    /** 소셜 플랫폼 고유 식별자. LOCAL 은 null */
    @Column(name = "provider_user_id", length = 255)
    private String providerUserId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AccountStatus status;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /** 탈퇴 시각. 미탈퇴는 null */
    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    /** 자식 엔티티가 공통 인증 필드를 채우도록 하는 생성자 */
    protected Account(String name, String email, String password,
                      AuthProvider provider, String providerUserId, String profileImageUrl,
                      LocalDate birthDate, String phone) {
        this.name = name;
        this.email = email;
        this.password = password;
        this.provider = provider;
        this.providerUserId = providerUserId;
        this.profileImageUrl = profileImageUrl;
        this.birthDate = birthDate;
        this.phone = phone;
        this.status = AccountStatus.ACTIVE;
    }

    /** 탈퇴 — 행은 남기고 개인정보만 파기 + 상태 전환 (soft delete) */
    public void withdraw() {
        this.status = AccountStatus.WITHDRAWN;
        this.deletedAt = LocalDateTime.now();
        this.name = null;
        this.email = null;
        this.password = null;
        this.profileImageUrl = null;
        this.providerUserId = null;   // null 이면 (provider, provider_user_id) UQ 안 걸려 재가입 가능
    }
}