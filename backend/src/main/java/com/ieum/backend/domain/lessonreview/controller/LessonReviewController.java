package com.ieum.backend.domain.lessonreview.controller;

import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.lessonreview.service.LessonReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.ResourceRegion;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpRange;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
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

    @GetMapping("/lessons")
    public ResponseEntity<List<ReviewLessonItemResponse>> listReviewLessons(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(lessonReviewService.listReviewLessons(principal.id()));
    }

    @GetMapping("/lessons/{lessonId}/summary-pdf")
    public ResponseEntity<SummaryPdfResponse> getSummaryPdf(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long lessonId) {
        return ResponseEntity.ok(lessonReviewService.getSummaryPdf(principal.id(), lessonId));
    }

    @GetMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<List<ReviewMessageItemResponse>> getMessages(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long sessionId) {
        return ResponseEntity.ok(lessonReviewService.getMessages(principal.id(), sessionId));
    }

    /**
     * 녹음 스트리밍 (인증 + 소유권 체크).
     * GET /api/v1/lesson-review/lessons/{lessonId}/recording
     * - 본인 강의가 아니면 404, 파일 없으면 404.
     * - Range 헤더 지원(206 Partial Content) → 영상 탐색 가능.
     */
    @GetMapping("/lessons/{lessonId}/recording")
    public ResponseEntity<ResourceRegion> getRecording(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long lessonId,
            @RequestHeader(value = HttpHeaders.RANGE, required = false) String rangeHeader)
            throws IOException {
        Resource resource = lessonReviewService.getRecordingResource(principal.id(), lessonId);
        long length = resource.contentLength();
        final long chunk = 1024 * 1024; // 1MB 청크

        ResourceRegion region;
        if (rangeHeader != null && !rangeHeader.isBlank()) {
            HttpRange httpRange = HttpRange.parseRanges(rangeHeader).get(0);
            long start = httpRange.getRangeStart(length);
            long end = httpRange.getRangeEnd(length);
            long rangeLength = Math.min(chunk, end - start + 1);
            region = new ResourceRegion(resource, start, rangeLength);
        } else {
            region = new ResourceRegion(resource, 0, Math.min(chunk, length));
        }

        MediaType contentType = MediaTypeFactory.getMediaType(resource)
                .orElse(MediaType.APPLICATION_OCTET_STREAM);
        return ResponseEntity.status(HttpStatus.PARTIAL_CONTENT)
                .contentType(contentType)
                .body(region);
    }
}