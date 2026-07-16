package com.ieum.backend.domain.auth.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 비밀번호 재설정 인증 코드.
 * 이메일로 6자리 코드를 보내고, code는 BCrypt로 해싱해 저장한다.
 * 같은 이메일에 여러 건이 쌓일 수 있어 createdAt 최신 1건을 검증에 쓴다.
 */
@Entity
@Table(name = "password_reset_codes")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PasswordResetCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "email", nullable = false, length = 255)
    private String email;

    /** 6자리 코드의 BCrypt 해시 (평문 저장 금지) */
    @Column(name = "code_hash", nullable = false, length = 255)
    private String codeHash;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "consumed", nullable = false)
    private boolean consumed;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Builder
    private PasswordResetCode(String email, String codeHash, LocalDateTime expiresAt) {
        this.email = email;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.consumed = false;
    }

    public boolean isExpired(LocalDateTime now) {
        return now.isAfter(expiresAt);
    }

    public void consume() {
        this.consumed = true;
    }
}
