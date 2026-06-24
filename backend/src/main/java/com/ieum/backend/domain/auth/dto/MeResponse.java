package com.ieum.backend.domain.auth.dto;

import com.ieum.backend.domain.auth.entity.Account;
import com.ieum.backend.domain.auth.entity.Role;

import java.time.LocalDate;

/** 내 정보 조회 응답 (학생/강사 공통 필드). */
public record MeResponse(
        Long id,
        String role,
        String name,
        String email,
        String phone,
        LocalDate birthDate,
        String profileImageUrl,
        String provider,
        String status
) {
    public static MeResponse of(Account account, Role role) {
        return new MeResponse(
                account.getId(),
                role.name(),
                account.getName(),
                account.getEmail(),
                account.getPhone(),
                account.getBirthDate(),
                account.getProfileImageUrl(),
                account.getProvider() == null ? null : account.getProvider().name(),
                account.getStatus().name()
        );
    }
}