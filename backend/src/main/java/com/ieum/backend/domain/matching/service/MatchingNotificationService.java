package com.ieum.backend.domain.matching.service;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class MatchingNotificationService {

    private final SimpMessagingTemplate messagingTemplate;

    public void notifyTutorApplied(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/matching/" + problemId,
                Map.of("type", "TUTOR_APPLIED", "tutorId", tutorId, "problemId", problemId)
        );
    }

    public void notifyMatched(Long problemId, Long tutorId, Long studentId) {
        messagingTemplate.convertAndSend(
                "/topic/matching/" + problemId,
                Map.of("type", "MATCHED", "tutorId", tutorId, "studentId", studentId, "problemId", problemId)
        );
    }

    public void notifySearchExpired(Long studentId) {
        messagingTemplate.convertAndSend(
                "/topic/student/" + studentId,
                Map.of("type", "SEARCH_EXPIRED", "studentId", studentId)
        );
    }

    public void notifyTutorUnavailable(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/matching/" + problemId,
                Map.of("type", "TUTOR_UNAVAILABLE", "tutorId", tutorId, "problemId", problemId)
        );
    }

    public void notifyTutorAvailable(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/matching/" + problemId,
                Map.of("type", "TUTOR_AVAILABLE", "tutorId", tutorId, "problemId", problemId)
        );
    }
}
