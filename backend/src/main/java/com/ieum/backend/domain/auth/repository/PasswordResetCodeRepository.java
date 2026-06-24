package com.ieum.backend.domain.auth.repository;

import com.ieum.backend.domain.auth.entity.PasswordResetCode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, Long> {

    /** 해당 이메일의 가장 최근 발급 코드 1건. */
    Optional<PasswordResetCode> findFirstByEmailOrderByCreatedAtDesc(String email);
}
