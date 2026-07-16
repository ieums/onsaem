package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;
import java.util.List;

/**
 * 소셜 가입 2단계 요청. check 에서 registered=false 였던 신규 사용자가 추가 정보를 담아 보냄
 * token 은 1단계와 동일한 소셜 토큰(서버가 재검증). 이메일/비번은 소셜이라 받지 않음
 * 강사 전용 필드는 role="tutor" 일 때만 쓰며, 필수 여부는 서비스에서 검증
 */
public record OAuthSignupRequest(
        @NotBlank String role,
        @NotBlank String token,
        @NotNull @Past LocalDate birthDate,
        @NotBlank @Size(max = 20) String phone,
        @Email @Size(max = 255) String email,   // 소셜이 이메일 미제공 시 폼에서 입력(선택)
        // ── 강사 전용 (role=tutor) ──
        @Size(max = 1000) String bio,
        @Size(max = 100) String school,
        @Size(max = 100) String major,
        @PositiveOrZero Integer experienceYears,
        String educationStatus,
        List<String> subjects
) {
}