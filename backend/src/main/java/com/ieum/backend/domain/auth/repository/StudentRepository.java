package com.ieum.backend.domain.auth.repository;

import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.domain.auth.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StudentRepository extends JpaRepository<Student, Long> {

    /** 소셜 로그인 식별 — 콜백의 provider + 고유 id 로 기존 학생 조회 */
    Optional<Student> findByProviderAndProviderUserId(AuthProvider provider, String providerUserId);

    /** LOCAL 로그인 / 이메일 중복 체크 */
    Optional<Student> findByEmail(String email);

    boolean existsByEmail(String email);
}