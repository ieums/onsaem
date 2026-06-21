package com.ieum.backend.domain.auth.dto;

import com.ieum.backend.domain.auth.entity.Account;
import com.ieum.backend.domain.auth.entity.Role;

/** 내 정보 조회 응답 (학생/강사 공통 필드). */
public record MeResponse(
        Long id,
        String role,
        String name,
        String email,
        String profileImageUrl,
        String status
) {
    public static MeResponse of(Account account, Role role) {
        return new MeResponse(
                account.getId(),
                role.name(),
                account.getName(),
                account.getEmail(),
                account.getProfileImageUrl(),
                account.getStatus().name()
        );
    }
}