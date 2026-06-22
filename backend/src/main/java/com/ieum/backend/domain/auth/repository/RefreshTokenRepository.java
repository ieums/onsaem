package com.ieum.backend.domain.auth.repository;

import com.ieum.backend.domain.auth.entity.RefreshToken;
import com.ieum.backend.domain.auth.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByRoleAndSubjectId(Role role, Long subjectId);

    void deleteByRoleAndSubjectId(Role role, Long subjectId);
}