package com.ieum.backend.domain.auth.controller;

import com.ieum.backend.domain.auth.dto.*;
import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.auth.service.AuthService;
import com.ieum.backend.domain.auth.service.PasswordResetService;
import com.ieum.backend.domain.auth.service.TokenService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final TokenService tokenService;
    private final PasswordResetService passwordResetService;

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

    /** 소셜 로그인 1단계 — 기존 회원이면 토큰, 신규면 가입 필요 응답 */
    @PostMapping("/oauth/{provider}/check")
    public ApiResponse<OAuthCheckResponse> oauthCheck(
            @PathVariable String provider,
            @Valid @RequestBody OAuthCheckRequest request) {
        return ApiResponse.ok(authService.oauthCheck(provider, request.token()));
    }

    /** 소셜 로그인 2단계 — 신규 사용자 추가정보 가입 + 토큰 발급 */
    @PostMapping("/oauth/{provider}/signup")
    public ApiResponse<TokenResponse> oauthSignup(
            @PathVariable String provider,
            @Valid @RequestBody OAuthSignupRequest request) {
        return ApiResponse.ok("회원가입이 완료되었습니다.", authService.oauthSignup(provider, request));
    }

    /** 비밀번호 재설정 코드 발송 — POST /api/v1/auth/password/forgot (LOCAL 계정만, 결과는 항상 200) */
    @PostMapping("/password/forgot")
    public ApiResponse<Void> forgotPassword(@Valid @RequestBody PasswordForgotRequest request) {
        passwordResetService.requestReset(request.email());
        return ApiResponse.ok("인증 코드를 보냈어요. 이메일을 확인해 주세요.", null);
    }

    /** 코드 검증 + 새 비밀번호 설정 — POST /api/v1/auth/password/reset */
    @PostMapping("/password/reset")
    public ApiResponse<Void> resetPassword(@Valid @RequestBody PasswordResetRequest request) {
        passwordResetService.confirmReset(request.email(), request.code(), request.newPassword());
        return ApiResponse.ok("비밀번호가 변경되었어요.", null);
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

    /** 프로필 수정 — PATCH /api/v1/auth/me */
    @PatchMapping("/me")
    public ApiResponse<MeResponse> updateMe(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestBody @Valid UpdateProfileRequest request) {
        return ApiResponse.ok("프로필이 수정되었습니다.", authService.updateMe(principal, request));
    }

    /** 프로필 사진 업로드 — POST /api/v1/auth/me/profile-image (multipart) */
    @PostMapping(value = "/me/profile-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<MeResponse> updateProfileImage(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestPart("image") MultipartFile image) {
        return ApiResponse.ok("프로필 사진이 변경되었습니다.",
                authService.updateProfileImage(principal, image));
    }
}