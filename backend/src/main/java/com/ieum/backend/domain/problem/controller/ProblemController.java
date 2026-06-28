package com.ieum.backend.domain.problem.controller;

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
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

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
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<ProblemCreateResponse> createProblem(
            @RequestPart("images") List<MultipartFile> images,
            @RequestPart("data") @Valid ProblemCreateRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {

        ProblemCreateResponse result = idempotencyService.execute(
                idempotencyKey, () -> problemService.createProblem(images, request));
        return ApiResponse.ok("문제가 등록되었습니다.", result);
    }

    /**
     * 여러 문제 감지 후 학생이 하나 선택해 확정 등록 (재OCR 없음)
     * POST /api/v1/problems/select
     */
    @PostMapping("/select")
    public ApiResponse<ProblemCreateResponse> selectProblem(
            @RequestBody @Valid ProblemSelectRequest request) {

        return ApiResponse.ok("문제가 등록되었습니다.", problemService.selectDetectedProblem(request));
    }

    /**
     * 강사 탐색 중인 문제 목록 조회
     * GET /api/v1/problems/searching?tutorId={tutorId}
     */
    @GetMapping("/searching")
    public ApiResponse<List<SearchingProblemResponse>> getSearchingProblems(@RequestParam Long tutorId) {
        return ApiResponse.ok("강사 탐색 중인 문제 목록입니다", problemService.getSearchingProblems(tutorId));
    }

    /**
     * 학생 문제 목록 조회
     * GET /api/v1/problems/student?studentId={studentId}
     */
    @GetMapping("/student")
    public ApiResponse<List<StudentProblemResponse>> getStudentProblems(@RequestParam Long studentId) {
        return ApiResponse.ok("학생 문제 목록입니다", problemService.getStudentProblems(studentId));
    }

    /**
     * 문제 단건 조회
     */
    @GetMapping("/{id}")
    public ApiResponse<ProblemDetailResponse> getProblem(@PathVariable Long id) {
        return ApiResponse.ok(problemService.getProblem(id));
    }

    /**
     * 분류 수정
     * PATCH /api/v1/problems/{id}/classification
     */
    @PatchMapping("/{id}/classification")
    public ApiResponse<ProblemDetailResponse> updateClassification(
            @PathVariable Long id,
            @RequestBody @Valid ClassificationUpdateRequest request) {

        return ApiResponse.ok("분류가 수정되었습니다.", problemService.updateClassification(id, request));
    }

    /**
     * (2) 여러 장 한 문제의 페이지 순서 재정렬
     * PATCH /api/v1/problems/{id}/page-order
     * body: { "order": [2, 0, 1] }  // 현재 인덱스의 순열
     */
    @PatchMapping("/{id}/page-order")
    public ApiResponse<ProblemDetailResponse> reorderPages(
            @PathVariable Long id,
            @RequestBody @Valid PageOrderUpdateRequest request) {

        return ApiResponse.ok("페이지 순서를 변경했습니다.",
                problemService.reorderPages(id, request.getOrder()));
    }

    /**
     * 문제 취소
     * DELETE /api/v1/problems/{id}
     */
    @DeleteMapping("/{id}")
    public ApiResponse<Void> cancelProblem(@PathVariable Long id) {
        problemService.cancelProblem(id);
        return ApiResponse.ok("문제가 취소되었습니다.", null);
    }
}