package com.ieum.backend.domain.auth.repository;

import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.domain.auth.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StudentRepository extends JpaRepository<Student, Long> {

    /** 소셜 로그인 식별 — 콜백의 provider + 고유 id 로 기존 학생 조회 */
    Optional<Student> findByProviderAndProviderUserId(AuthProvider provider, String providerUserId);

    /** LOCAL 로그인 / 이메일 중복 체크 */
    Optional<Student> findByEmail(String email);

    boolean existsByEmail(String email);

    /** 관리자 회원관리 — 이름/이메일 부분일치 검색(최신 가입순) */
    List<Student> findTop200ByNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByCreatedAtDesc(
            String name, String email);

    List<Student> findTop200ByOrderByCreatedAtDesc();

    /** 관리자 학생 목록 — 페이지 슬라이스(최신 가입순). */
    org.springframework.data.domain.Page<Student> findAllByOrderByCreatedAtDesc(
            org.springframework.data.domain.Pageable pageable);

    org.springframework.data.domain.Page<Student>
    findByNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByCreatedAtDesc(
            String name, String email, org.springframework.data.domain.Pageable pageable);
}