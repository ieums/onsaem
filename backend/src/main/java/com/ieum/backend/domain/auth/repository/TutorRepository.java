package com.ieum.backend.domain.auth.repository;

import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.domain.auth.entity.Tutor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TutorRepository extends JpaRepository<Tutor, Long> {

    Optional<Tutor> findByProviderAndProviderUserId(AuthProvider provider, String providerUserId);

    Optional<Tutor> findByEmail(String email);

    boolean existsByEmail(String email);

    List<Tutor> findAllByIdIn(List<Long> ids);

    /** 관리자 회원관리 — 이름/이메일 부분일치 검색(최신 가입순) */
    List<Tutor> findTop200ByNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByCreatedAtDesc(
            String name, String email);

    List<Tutor> findTop200ByOrderByCreatedAtDesc();

    /** 관리자 강사 목록 — 페이지 슬라이스(최신 가입순). */
    org.springframework.data.domain.Page<Tutor> findAllByOrderByCreatedAtDesc(
            org.springframework.data.domain.Pageable pageable);

    org.springframework.data.domain.Page<Tutor>
    findByNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByCreatedAtDesc(
            String name, String email, org.springframework.data.domain.Pageable pageable);
}