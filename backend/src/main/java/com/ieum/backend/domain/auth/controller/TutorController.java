package com.ieum.backend.domain.auth.controller;

import com.ieum.backend.domain.auth.dto.SettlementAccountRequest;
import com.ieum.backend.domain.auth.dto.SettlementAccountResponse;
import com.ieum.backend.domain.auth.dto.TutorAvailabilityRequest;
import com.ieum.backend.domain.auth.dto.TutorProfileResponse;
import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.auth.service.TutorService;
import com.ieum.backend.global.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/tutors")
@RequiredArgsConstructor
public class TutorController {

    private final TutorService tutorService;

    @GetMapping("/{tutorId}")
    public ApiResponse<TutorProfileResponse> getProfile(@PathVariable Long tutorId) {
        return ApiResponse.ok(tutorService.getProfile(tutorId));
    }

    @PatchMapping("/{tutorId}/availability")
    public ApiResponse<Void> updateAvailability(
            @PathVariable Long tutorId,
            @RequestBody TutorAvailabilityRequest request) {
        tutorService.updateAvailability(tutorId, request.available());
        return ApiResponse.ok("가용 상태가 업데이트되었습니다.", null);
    }

    /** 정산 계좌 조회 — GET /api/v1/tutors/me/settlement-account (로그인 강사 본인) */
    @GetMapping("/me/settlement-account")
    public ApiResponse<SettlementAccountResponse> getSettlementAccount(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok("정산 계좌를 조회했습니다.", tutorService.getSettlementAccount(principal.id()));
    }

    /** 정산 계좌 등록·수정 — PATCH /api/v1/tutors/me/settlement-account (로그인 강사 본인) */
    @PatchMapping("/me/settlement-account")
    public ApiResponse<SettlementAccountResponse> updateSettlementAccount(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestBody SettlementAccountRequest request) {
        return ApiResponse.ok("정산 계좌가 저장되었습니다.", tutorService.updateSettlementAccount(principal.id(), request));
    }

    /** 학력 증빙 서류 재제출 — POST /api/v1/tutors/me/verification-document (multipart). 재제출 시 인증 PENDING 으로. */
    @PostMapping(value = "/me/verification-document", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<Void> reuploadVerificationDocument(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestPart("document") MultipartFile document) {
        tutorService.reuploadVerificationDocument(principal.id(), document);
        return ApiResponse.ok("증빙 서류가 제출되었습니다. 관리자 승인을 기다려 주세요.", null);
    }
}
