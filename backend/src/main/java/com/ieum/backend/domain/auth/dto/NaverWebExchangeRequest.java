package com.ieum.backend.domain.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record NaverWebExchangeRequest(
        @NotBlank String code,
        @NotBlank String state
) {
}