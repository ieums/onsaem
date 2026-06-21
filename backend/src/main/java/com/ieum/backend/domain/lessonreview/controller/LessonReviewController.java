package com.ieum.backend.domain.lessonreview.controller;

import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.lessonreview.service.LessonReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/lesson-review")
@RequiredArgsConstructor
public class LessonReviewController {

    private final LessonReviewService lessonReviewService;

    @PostMapping("/sessions")
    public ResponseEntity<CreateReviewSessionResponse> createSession(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody CreateReviewSessionRequest request) {
        CreateReviewSessionResponse response =
                lessonReviewService.createSession(principal.id(), request.lessonId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<SendReviewMessageResponse> sendMessage(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long sessionId,
            @Valid @RequestBody SendReviewMessageRequest request) {
        SendReviewMessageResponse response =
                lessonReviewService.sendMessage(principal.id(), sessionId, request.content());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/sessions")
    public ResponseEntity<List<ReviewSessionListItemResponse>> listSessions(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(lessonReviewService.listSessions(principal.id()));
    }

    @GetMapping("/lessons/{lessonId}/summary-pdf")
    public ResponseEntity<SummaryPdfResponse> getSummaryPdf(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long lessonId) {
        return ResponseEntity.ok(lessonReviewService.getSummaryPdf(principal.id(), lessonId));
    }
}