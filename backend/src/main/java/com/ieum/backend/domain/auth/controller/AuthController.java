package com.ieum.backend.domain.auth.controller;

import com.ieum.backend.domain.auth.dto.LoginRequest;
import com.ieum.backend.domain.auth.dto.MeResponse;
import com.ieum.backend.domain.auth.dto.OAuthLoginRequest;
import com.ieum.backend.domain.auth.dto.StudentSignupRequest;
import com.ieum.backend.domain.auth.dto.TokenRefreshRequest;
import com.ieum.backend.domain.auth.dto.TokenResponse;
import com.ieum.backend.domain.auth.dto.TutorSignupRequest;
import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.auth.service.AuthService;
import com.ieum.backend.domain.auth.service.TokenService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final TokenService tokenService;

    @PostMapping("/student/signup")
    public ApiResponse<TokenResponse> signupStudent(@Valid @RequestBody StudentSignupRequest request) {
        return ApiResponse.ok("회원가입이 완료되었습니다.", authService.signupStudent(request));
    }

    @PostMapping("/tutor/signup")
    public ApiResponse<TokenResponse> signupTutor(@Valid @RequestBody TutorSignupRequest request) {
        return ApiResponse.ok("회원가입이 완료되었습니다.", authService.signupTutor(request));
    }

    @PostMapping("/student/login")
    public ApiResponse<TokenResponse> loginStudent(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok("로그인되었습니다.", authService.loginStudent(request));
    }

    @PostMapping("/tutor/login")
    public ApiResponse<TokenResponse> loginTutor(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok("로그인되었습니다.", authService.loginTutor(request));
    }

    @PostMapping("/oauth/{provider}")
    public ApiResponse<TokenResponse> oauthLogin(
            @PathVariable String provider,
            @Valid @RequestBody OAuthLoginRequest request) {
        return ApiResponse.ok("로그인되었습니다.",
                authService.oauthLogin(provider, request.role(), request.token()));
    }

    @PostMapping("/refresh")
    public ApiResponse<TokenResponse> refresh(@Valid @RequestBody TokenRefreshRequest request) {
        return ApiResponse.ok("토큰이 재발급되었습니다.", tokenService.reissue(request.refreshToken()));
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout(@AuthenticationPrincipal AuthPrincipal principal) {
        tokenService.logout(principal);
        return ApiResponse.ok("로그아웃되었습니다.", null);
    }

    @GetMapping("/me")
    public ApiResponse<MeResponse> me(@AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(authService.getMe(principal));
    }
}