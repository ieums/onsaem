package com.ieum.backend.domain.user.controller;

import com.ieum.backend.domain.user.service.AiTutorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import java.util.List;

@RestController
@RequestMapping("/api/v1/ai-tutor")
@RequiredArgsConstructor
public class AiTutorController {

    private final AiTutorService tutorService;

    @PostMapping("/sessions")
    public ResponseEntity<CreateSessionResponse> createSession(
            @RequestHeader("X-Student-Id") Long studentId,
            @Valid @RequestBody CreateSessionRequest request) {
        CreateSessionResponse response =
                tutorService.createSession(studentId, request.problemId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<SendMessageResponse> sendMessage(
            @RequestHeader("X-Student-Id") Long studentId,
            @PathVariable Long sessionId,
            @Valid @RequestBody SendMessageRequest request) {
        SendMessageResponse response =
                tutorService.sendMessage(studentId, sessionId, request.content());
        return ResponseEntity.ok(response);
    }
    @GetMapping("/sessions")
    public ResponseEntity<List<SessionListItemResponse>> listSessions(
            @RequestHeader("X-Student-Id") Long studentId) {
        return ResponseEntity.ok(tutorService.listSessions(studentId));
    }
    @GetMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<List<MessageItemResponse>> getMessages(
            @RequestHeader("X-Student-Id") Long studentId,
            @PathVariable Long sessionId) {
        return ResponseEntity.ok(tutorService.getMessages(studentId, sessionId));
    }
}