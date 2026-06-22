package com.ieum.backend.domain.auth.dto;

/** 회원가입/로그인 성공 시 발급되는 토큰 묶음. */
public record TokenResponse(String accessToken, String refreshToken, String role) {
}