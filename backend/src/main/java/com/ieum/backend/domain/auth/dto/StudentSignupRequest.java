package com.ieum.backend.domain.auth.dto;

import com.ieum.backend.domain.auth.PasswordPolicy;
import jakarta.validation.constraints.*;

import java.time.LocalDate;

public record StudentSignupRequest(
        @NotBlank @Email String email,
        @NotBlank @Pattern(regexp = PasswordPolicy.REGEX, message = PasswordPolicy.MESSAGE) String password,
        @NotBlank @Size(max = 50) String name,
        @NotNull @Past LocalDate birthDate,
        @NotBlank @Size(max = 20) String phone
) {
}
