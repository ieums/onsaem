package com.ieum.backend.domain.problem.controller;

import com.ieum.backend.domain.problem.dto.request.ClassificationUpdateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemSelectRequest;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.dto.response.ProblemDetailResponse;
import com.ieum.backend.domain.problem.dto.response.SearchingProblemResponse;
import com.ieum.backend.domain.problem.dto.response.StudentProblemResponse;
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

    /**
     * 문제 등록 (이미지 1~N장)
     * multipart/form-data
     *   - images: List<MultipartFile>
     *   - data:   ProblemCreateRequest (JSON)
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<ProblemCreateResponse> createProblem(
            @RequestPart("images") List<MultipartFile> images,
            @RequestPart("data") @Valid ProblemCreateRequest request) {

        return ApiResponse.ok("문제가 등록되었습니다.", problemService.createProblem(images, request));
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
     * 문제 취소
     * DELETE /api/v1/problems/{id}
     */
    @DeleteMapping("/{id}")
    public ApiResponse<Void> cancelProblem(@PathVariable Long id) {
        problemService.cancelProblem(id);
        return ApiResponse.ok("문제가 취소되었습니다.", null);
    }
}