package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** 비밀번호 재설정 코드 발송 요청. */
public record PasswordForgotRequest(
        @NotBlank @Email String email
) {
}
