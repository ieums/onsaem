package com.ieum.backend.domain.review.controller;

import com.ieum.backend.domain.review.dto.request.CreateReviewRequest;
import com.ieum.backend.domain.review.dto.request.UpdateReviewRequest;
import com.ieum.backend.domain.review.dto.response.ReviewResponse;
import com.ieum.backend.domain.review.dto.response.ReviewSummaryResponse;
import com.ieum.backend.domain.review.service.ReviewService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 튜터 평점·후기 리뷰.
 * studentId는 인증 도입 전까지 파라미터로 받음(이후 SecurityContext로 교체).
 */
@RestController
@RequestMapping("/api/v1/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    /** 리뷰 작성 — POST /api/v1/reviews?studentId= */
    @PostMapping
    public ApiResponse<ReviewResponse> create(
            @RequestParam Long studentId,
            @RequestBody @Valid CreateReviewRequest request) {
        return ApiResponse.ok("리뷰가 등록되었습니다.", reviewService.create(studentId, request));
    }

    /** 튜터 리뷰 목록 — GET /api/v1/reviews/tutors/{tutorId} */
    @GetMapping("/tutors/{tutorId}")
    public ApiResponse<List<ReviewResponse>> getByTutor(@PathVariable Long tutorId) {
        return ApiResponse.ok(reviewService.getByTutor(tutorId));
    }

    /** 튜터 리뷰 요약(평균·분포) — GET /api/v1/reviews/tutors/{tutorId}/summary */
    @GetMapping("/tutors/{tutorId}/summary")
    public ApiResponse<ReviewSummaryResponse> getSummary(@PathVariable Long tutorId) {
        return ApiResponse.ok(reviewService.getSummary(tutorId));
    }

    /** 리뷰 수정 — PATCH /api/v1/reviews/{id}?studentId= */
    @PatchMapping("/{id}")
    public ApiResponse<ReviewResponse> update(
            @PathVariable Long id,
            @RequestParam Long studentId,
            @RequestBody @Valid UpdateReviewRequest request) {
        return ApiResponse.ok("리뷰가 수정되었습니다.", reviewService.update(id, studentId, request));
    }

    /** 리뷰 삭제 — DELETE /api/v1/reviews/{id}?studentId= */
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            @PathVariable Long id,
            @RequestParam Long studentId) {
        reviewService.delete(id, studentId);
        return ApiResponse.ok("리뷰가 삭제되었습니다.", null);
    }
}
