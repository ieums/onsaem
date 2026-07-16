package com.ieum.backend.domain.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 관리자 콘솔(/admin) 로그인 계정. 세션 폼 로그인의 주체.
 * 공개 가입이 아니라 콘솔 안에서 로그인한 관리자가 새 계정을 추가한다.
 * 앱 기동 시 테이블이 비었으면 application.yml 의 admin.username/password 를 BCrypt 로 시드한다.
 */
@Entity
@Table(name = "admin", uniqueConstraints = {
        @UniqueConstraint(name = "uk_admin_username", columnNames = "username")
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Admin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String username;

    /** BCrypt 해시 */
    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public Admin(String username, String passwordHash) {
        this.username = username;
        this.passwordHash = passwordHash;
    }
}
