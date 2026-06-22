package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** 학생/강사 공통 로그인 요청 (LOCAL). */
public record LoginRequest(
        @NotBlank @Email String email,
        @NotBlank String password
) {
}