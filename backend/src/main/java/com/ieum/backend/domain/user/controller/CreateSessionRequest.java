package com.ieum.backend.domain.user.controller;

import jakarta.validation.constraints.NotNull;

public record CreateSessionRequest(
        @NotNull(message = "problemId는 필수입니다.") Long problemId
) {
}