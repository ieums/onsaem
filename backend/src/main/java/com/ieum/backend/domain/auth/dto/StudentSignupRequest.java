package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;

public record StudentSignupRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, max = 64) String password,
        @NotBlank @Size(max = 50) String name,
        @NotNull @Past LocalDate birthDate,
        @NotBlank @Size(max = 20) String phone
) {
}
