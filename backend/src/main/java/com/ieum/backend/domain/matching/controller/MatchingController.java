package com.ieum.backend.domain.matching.controller;

import com.ieum.backend.domain.matching.dto.request.MatchingAcceptRequest;
import com.ieum.backend.domain.matching.dto.request.MatchingApplyRequest;
import com.ieum.backend.domain.matching.dto.request.MatchingCancelConfirmRequest;
import com.ieum.backend.domain.matching.dto.request.MatchingConfirmRequest;
import com.ieum.backend.domain.matching.dto.request.MatchingStartRequest;
import com.ieum.backend.domain.matching.dto.response.ApplicantResponse;
import com.ieum.backend.domain.matching.dto.response.TutorApplicationResponse;
import com.ieum.backend.domain.matching.service.MatchingService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/matching")
@RequiredArgsConstructor
public class MatchingController {

    private final MatchingService matchingService;

    @PostMapping("/{problemId}/start")
    public ApiResponse<Void> startSearching(
            @PathVariable Long problemId,
            @Valid @RequestBody MatchingStartRequest request) {
        matchingService.startSearching(problemId, request.getMinutes());
        return ApiResponse.ok("강사 탐색을 시작했습니다", null);
    }

    @PostMapping("/{problemId}/apply")
    public ApiResponse<Void> applyToLesson(
            @PathVariable Long problemId,
            @Valid @RequestBody MatchingApplyRequest request) {
        matchingService.applyToLesson(problemId, request.getTutorId());
        return ApiResponse.ok("강의 신청이 완료되었습니다", null);
    }

    @GetMapping("/{problemId}/applicants")
    public ApiResponse<List<ApplicantResponse>> getApplicants(
            @PathVariable Long problemId) {
        return ApiResponse.ok(matchingService.getApplicants(problemId));
    }

    @PostMapping("/{problemId}/accept")
    public ApiResponse<Void> acceptTutor(
            @PathVariable Long problemId,
            @Valid @RequestBody MatchingAcceptRequest request) {
        matchingService.acceptTutor(problemId, request.getTutorId());
        return ApiResponse.ok("강사를 수락했습니다", null);
    }

    @PostMapping("/{problemId}/extend")
    public ApiResponse<Void> extendSearch(
            @PathVariable Long problemId,
            @Valid @RequestBody MatchingStartRequest request) {
        matchingService.extendSearch(problemId, request.getMinutes());
        return ApiResponse.ok("탐색 시간을 연장했습니다", null);
    }

    @DeleteMapping("/{problemId}/apply")
    public ApiResponse<Void> cancelApplication(
            @PathVariable Long problemId,
            @RequestParam Long tutorId) {
        matchingService.cancelApplication(problemId, tutorId);
        return ApiResponse.ok("신청이 취소되었습니다", null);
    }

    @PostMapping("/{problemId}/confirm")
    public ApiResponse<Void> confirmMatch(
            @PathVariable Long problemId,
            @Valid @RequestBody MatchingConfirmRequest request) {
        matchingService.confirmMatch(problemId, request.getTutorId(), request.getConfirmedBy());
        return ApiResponse.ok("확인 처리되었습니다", null);
    }

    @PostMapping("/{problemId}/cancel-confirm")
    public ApiResponse<Void> cancelMatch(
            @PathVariable Long problemId,
            @Valid @RequestBody MatchingCancelConfirmRequest request) {
        matchingService.cancelMatch(problemId, request.getTutorId(), request.getCancelledBy());
        return ApiResponse.ok("취소 처리되었습니다", null);
    }

    @PostMapping("/{problemId}/reject")
    public ApiResponse<Void> rejectProblem(
            @PathVariable Long problemId,
            @RequestParam Long tutorId) {
        matchingService.rejectProblem(problemId, tutorId);
        return ApiResponse.ok("문제를 거절했습니다", null);
    }

    @GetMapping("/tutor/{tutorId}/applications")
    public ApiResponse<List<TutorApplicationResponse>> getTutorApplications(
            @PathVariable Long tutorId) {
        return ApiResponse.ok("강사 신청 목록입니다", matchingService.getTutorApplications(tutorId));
    }

    @PostMapping("/tutor/{tutorId}/start-lesson")
    public ApiResponse<Void> tutorStartLesson(@PathVariable Long tutorId) {
        matchingService.tutorStartLesson(tutorId);
        return ApiResponse.ok("수업 시작 처리가 완료되었습니다", null);
    }

    @PostMapping("/tutor/{tutorId}/end-lesson")
    public ApiResponse<Void> tutorEndLesson(@PathVariable Long tutorId) {
        matchingService.tutorEndLesson(tutorId);
        return ApiResponse.ok("수업 종료 처리가 완료되었습니다", null);
    }
}
