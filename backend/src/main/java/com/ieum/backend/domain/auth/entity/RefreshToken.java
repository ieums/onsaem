package com.ieum.backend.domain.auth.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 발급된 refresh 토큰 저장소. (role, subject_id) 당 1개 — 최신 로그인만 유효.
 * 로그아웃 시 삭제, 재발급 시 회전(rotate)
 */
@Entity
@Table(name = "refresh_token", uniqueConstraints = {
        @UniqueConstraint(name = "uk_refresh_token_owner", columnNames = {"role", "subject_id"})
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role;

    /** student.id 또는 tutor.id */
    @Column(name = "subject_id", nullable = false)
    private Long subjectId;

    @Column(nullable = false, length = 512)
    private String token;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Builder
    private RefreshToken(Role role, Long subjectId, String token, LocalDateTime expiresAt) {
        this.role = role;
        this.subjectId = subjectId;
        this.token = token;
        this.expiresAt = expiresAt;
    }

    /** 재발급 시 새 토큰/만료로 교체 (회전) */
    public void rotate(String token, LocalDateTime expiresAt) {
        this.token = token;
        this.expiresAt = expiresAt;
    }

    public boolean isExpired() {
        return expiresAt.isBefore(LocalDateTime.now());
    }
}