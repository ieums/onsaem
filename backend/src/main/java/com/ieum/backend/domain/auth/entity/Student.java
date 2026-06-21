package com.ieum.backend.domain.auth.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 학생 계정. 인증 공통 필드는 Account 에서 상속받고,
 * 학생 전용 도메인 필드는 추후 필요 시 여기에 추가한다.
 */
@Entity
@Table(name = "student", uniqueConstraints = {
        @UniqueConstraint(name = "uk_student_provider", columnNames = {"provider", "provider_user_id"})
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Student extends Account {

    @Builder
    private Student(String name, String email, String password,
                    AuthProvider provider, String providerUserId, String profileImageUrl) {
        super(name, email, password, provider, providerUserId, profileImageUrl);
    }
}