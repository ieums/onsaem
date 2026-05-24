package com.ieum.backend.domain.problem.controller;

import com.ieum.backend.domain.problem.dto.request.ClassificationUpdateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.dto.response.ProblemDetailResponse;
import com.ieum.backend.domain.problem.service.ProblemService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
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
    public ResponseEntity<ProblemCreateResponse> createProblem(
            @RequestPart("images") List<MultipartFile> images,
            @RequestPart("data") @Valid ProblemCreateRequest request) {

        return ResponseEntity.ok(problemService.createProblem(images, request));
    }

    /**
     * 문제 단건 조회
     */
    @GetMapping("/{id}")
    public ResponseEntity<ProblemDetailResponse> getProblem(@PathVariable Long id) {
        return ResponseEntity.ok(problemService.getProblem(id));
    }

    /**
     * 분류 수정
     * PATCH /api/v1/problems/{id}/classification
     */
    @PatchMapping("/{id}/classification")
    public ResponseEntity<ProblemDetailResponse> updateClassification(
            @PathVariable Long id,
            @RequestBody @Valid ClassificationUpdateRequest request) {

        ProblemDetailResponse response = problemService.updateClassification(id, request);
        return ResponseEntity.ok(response);
    }

    /**
     * 문제 취소
     * DELETE /api/v1/problems/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancelProblem(@PathVariable Long id) {
        problemService.cancelProblem(id);
        return ResponseEntity.noContent().build();
    }
}