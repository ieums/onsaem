package com.ieum.backend.domain.auth.dto;

import com.ieum.backend.domain.auth.PasswordPolicy;
import jakarta.validation.constraints.*;

import java.time.LocalDate;
import java.util.List;

public record TutorSignupRequest(
        @NotBlank @Email String email,
        @NotBlank @Pattern(regexp = PasswordPolicy.REGEX, message = PasswordPolicy.MESSAGE) String password,
        @NotBlank @Size(max = 50) String name,
        @NotNull @Past LocalDate birthDate,
        @NotBlank @Size(max = 20) String phone,
        @Size(max = 1000) String bio,
        @Size(max = 100) String school,
        @Size(max = 100) String major,
        @PositiveOrZero Integer experienceYears,
        @NotBlank String educationStatus,
        List<String> subjects
) {
}