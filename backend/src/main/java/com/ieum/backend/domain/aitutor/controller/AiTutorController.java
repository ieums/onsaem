package com.ieum.backend.domain.aitutor.controller;

import com.ieum.backend.domain.aitutor.service.AiTutorService;
import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;

@RestController
@RequestMapping("/api/v1/ai-tutor")
@RequiredArgsConstructor
public class AiTutorController {

    private final AiTutorService tutorService;

    @PostMapping("/sessions")
    public ResponseEntity<CreateSessionResponse> createSession(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody CreateSessionRequest request) {
        CreateSessionResponse response =
                tutorService.createSession(principal.id(), request.problemId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<SendMessageResponse> sendMessage(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long sessionId,
            @Valid @RequestBody SendMessageRequest request) {
        SendMessageResponse response =
                tutorService.sendMessage(principal.id(), sessionId, request.content());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/sessions")
    public ResponseEntity<List<SessionListItemResponse>> listSessions(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ResponseEntity.ok(tutorService.listSessions(principal.id()));
    }

    @GetMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<List<MessageItemResponse>> getMessages(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long sessionId) {
        return ResponseEntity.ok(tutorService.getMessages(principal.id(), sessionId));
    }

    @PatchMapping("/sessions/{sessionId}/close")
    public ResponseEntity<Void> closeSession(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long sessionId) {
        tutorService.closeSession(principal.id(), sessionId);
        return ResponseEntity.noContent().build();
    }
}