package com.ieum.backend.domain.auth.dto;

import com.ieum.backend.domain.auth.PasswordPolicy;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** 코드 검증 + 새 비밀번호 설정 요청. */
public record PasswordResetRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 6, max = 6) String code,
        @NotBlank @Pattern(regexp = PasswordPolicy.REGEX, message = PasswordPolicy.MESSAGE)
        String newPassword
) {
}
