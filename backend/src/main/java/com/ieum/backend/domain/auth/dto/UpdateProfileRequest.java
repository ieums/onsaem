package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.Size;

import java.time.LocalDate;

/** 프로필 부분 수정 — 마이페이지. 보낸 값(null 아님)만 갱신. */
public record UpdateProfileRequest(
        @Size(max = 50) String name,
        @Size(max = 20) String phone,
        LocalDate birthDate,
        @Size(max = 500) String profileImageUrl
) {
}
