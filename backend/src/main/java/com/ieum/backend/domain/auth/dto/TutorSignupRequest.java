package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;

public record TutorSignupRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, max = 64) String password,
        @NotBlank @Size(max = 50) String name,
        @NotNull @Past LocalDate birthDate,
        @NotBlank @Size(max = 20) String phone,
        @Size(max = 1000) String bio,
        @Size(max = 100) String school,
        @Size(max = 100) String major,
        @PositiveOrZero Integer experienceYears,
        @NotBlank String educationStatus
) {
}