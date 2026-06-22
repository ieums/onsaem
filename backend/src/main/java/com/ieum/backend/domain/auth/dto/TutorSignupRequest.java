package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TutorSignupRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, max = 64) String password,
        @NotBlank @Size(max = 50) String name,
        @Size(max = 1000) String bio,
        @Size(max = 100) String school,
        @Size(max = 100) String major
) {
}