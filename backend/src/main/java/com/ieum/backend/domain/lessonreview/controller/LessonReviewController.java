package com.ieum.backend.domain.lessonreview.controller;

import com.ieum.backend.domain.lessonreview.service.LessonReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/lesson-review")
@RequiredArgsConstructor
public class LessonReviewController {

    private final LessonReviewService lessonReviewService;

    @PostMapping("/sessions")
    public ResponseEntity<CreateReviewSessionResponse> createSession(
            @RequestHeader("X-Student-Id") Long studentId,
            @Valid @RequestBody CreateReviewSessionRequest request) {
        CreateReviewSessionResponse response =
                lessonReviewService.createSession(studentId, request.lessonId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<SendReviewMessageResponse> sendMessage(
            @RequestHeader("X-Student-Id") Long studentId,
            @PathVariable Long sessionId,
            @Valid @RequestBody SendReviewMessageRequest request) {
        SendReviewMessageResponse response =
                lessonReviewService.sendMessage(studentId, sessionId, request.content());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/sessions")
    public ResponseEntity<List<ReviewSessionListItemResponse>> listSessions(
            @RequestHeader("X-Student-Id") Long studentId) {
        return ResponseEntity.ok(lessonReviewService.listSessions(studentId));
    }

    @GetMapping("/lessons/{lessonId}/summary-pdf")
    public ResponseEntity<SummaryPdfResponse> getSummaryPdf(
            @RequestHeader("X-Student-Id") Long studentId,
            @PathVariable Long lessonId) {
        return ResponseEntity.ok(lessonReviewService.getSummaryPdf(studentId, lessonId));
    }
}