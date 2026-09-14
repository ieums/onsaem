package com.ieum.backend.domain.problem.controller;

import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.problem.dto.request.ClassificationUpdateRequest;
import com.ieum.backend.domain.problem.dto.request.PageOrderUpdateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemSelectRequest;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.dto.response.ProblemDetailResponse;
import com.ieum.backend.domain.problem.dto.response.SearchingProblemResponse;
import com.ieum.backend.domain.problem.dto.response.StudentProblemResponse;
import com.ieum.backend.domain.problem.service.ProblemIdempotencyService;
import com.ieum.backend.domain.problem.service.ProblemService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * 문제 등록·조회·수정.
 * 학생·강사 ID는 요청값이 아니라 JWT 인증 주체(@AuthenticationPrincipal)에서 가져온다.
 * 역할별 접근 제한은 SecurityConfig에서 건다(등록·수정·취소는 학생, 탐색 목록은 강사).
 */
@RestController
@RequestMapping("/api/v1/problems")
@RequiredArgsConstructor
public class ProblemController {

    private final ProblemService problemService;
    private final ProblemIdempotencyService idempotencyService;

    /**
     * 문제 등록 (이미지 1~N장)
     * multipart/form-data
     *   - images: List<MultipartFile>
     *   - data:   ProblemCreateRequest (JSON)
     *
     * Idempotency-Key 헤더(선택): 같은 키의 재요청은 처음 결과를 그대로 반환해 중복 등록을 막는다.
     * 키는 학생별로 구분해 다른 학생의 키와 섞이지 않게 한다.
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<ProblemCreateResponse> createProblem(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestPart("images") List<MultipartFile> images,
            @RequestPart("data") @Valid ProblemCreateRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {

        Long studentId = principal.id();
        String key = (idempotencyKey == null || idempotencyKey.isBlank())
                ? null : "create:" + studentId + ":" + idempotencyKey;
        ProblemCreateResponse result = idempotencyService.execute(
                key, () -> problemService.createProblem(images, request, studentId));
        return ApiResponse.ok("문제가 등록되었습니다.", result);
    }

    /**
     * 여러 문제 감지 후 학생이 하나 선택해 확정 등록 (재OCR 없음)
     * POST /api/v1/problems/select
     *
     * detectionId는 한 번만 쓰이는 값이라 그 자체를 멱등 키로 쓴다 —
     * 버튼 연타·네트워크 재시도로 같은 선택이 다시 와도 처음 결과를 그대로 돌려준다.
     */
    @PostMapping("/select")
    public ApiResponse<ProblemCreateResponse> selectProblem(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestBody @Valid ProblemSelectRequest request) {

        Long studentId = principal.id();
        ProblemCreateResponse result = idempotencyService.execute(
                "select:" + studentId + ":" + request.getDetectionId(),
                () -> problemService.selectDetectedProblem(request, studentId));
        return ApiResponse.ok("문제가 등록되었습니다.", result);
    }

    /**
     * 강사 탐색 중인 문제 목록 조회 (로그인한 강사의 담당 과목 기준)
     * GET /api/v1/problems/searching
     */
    @GetMapping("/searching")
    public ApiResponse<List<SearchingProblemResponse>> getSearchingProblems(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok("강사 탐색 중인 문제 목록입니다", problemService.getSearchingProblems(principal.id()));
    }

    /**
     * 내 문제 목록 조회 (로그인한 학생)
     * GET /api/v1/problems/student
     */
    @GetMapping("/student")
    public ApiResponse<List<StudentProblemResponse>> getStudentProblems(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok("학생 문제 목록입니다", problemService.getStudentProblems(principal.id()));
    }

    /**
     * 문제 단건 조회 (학생은 본인 문제만)
     */
    @GetMapping("/{id}")
    public ApiResponse<ProblemDetailResponse> getProblem(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long id) {
        return ApiResponse.ok(problemService.getProblem(id, principal.id(), principal.role()));
    }

    /**
     * 분류 수정 (본인 문제만)
     * PATCH /api/v1/problems/{id}/classification
     */
    @PatchMapping("/{id}/classification")
    public ApiResponse<ProblemDetailResponse> updateClassification(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long id,
            @RequestBody @Valid ClassificationUpdateRequest request) {

        return ApiResponse.ok("분류가 수정되었습니다.",
                problemService.updateClassification(id, request, principal.id()));
    }

    /**
     * 여러 장 한 문제의 페이지 순서 재정렬 (본인 문제만)
     * PATCH /api/v1/problems/{id}/page-order
     * body: { "order": [2, 0, 1] }  // 현재 인덱스의 순열
     */
    @PatchMapping("/{id}/page-order")
    public ApiResponse<ProblemDetailResponse> reorderPages(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long id,
            @RequestBody @Valid PageOrderUpdateRequest request) {

        return ApiResponse.ok("페이지 순서를 변경했습니다.",
                problemService.reorderPages(id, request.getOrder(), principal.id()));
    }

    /**
     * 문제 취소 (본인 문제만)
     * DELETE /api/v1/problems/{id}
     */
    @DeleteMapping("/{id}")
    public ApiResponse<Void> cancelProblem(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long id) {
        problemService.cancelProblem(id, principal.id());
        return ApiResponse.ok("문제가 취소되었습니다.", null);
    }
}
