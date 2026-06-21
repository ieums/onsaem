package com.ieum.backend.domain.matching.service;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class MatchingNotificationService {

    private final SimpMessagingTemplate messagingTemplate;

    public void notifyTutorApplied(Long problemId, Long tutorId, Long studentId) {
        messagingTemplate.convertAndSend(
                "/topic/student/" + studentId,
                Map.of("type", "TUTOR_APPLIED", "studentId", studentId, "problemId", problemId, "tutorId", tutorId)
        );
    }

    public void notifyMatched(Long problemId, Long tutorId, Long studentId, Long lessonId, String channelName, List<String> imageUrls) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "MATCHED");
        payload.put("tutorId", tutorId);
        payload.put("studentId", studentId);
        payload.put("problemId", problemId);
        payload.put("lessonId", lessonId);
        payload.put("channelName", channelName);
        payload.put("imageUrls", imageUrls);
        messagingTemplate.convertAndSend("/topic/matching/" + problemId, payload);
    }

    public void notifySearchExpiringSoon(Long studentId, Long problemId) {
        messagingTemplate.convertAndSend(
                "/topic/student/" + studentId,
                Map.of("type", "SEARCH_EXPIRING_SOON", "studentId", studentId, "problemId", problemId)
        );
    }

    public void notifySearchExpired(Long studentId, Long problemId) {
        messagingTemplate.convertAndSend(
                "/topic/student/" + studentId,
                Map.of("type", "SEARCH_EXPIRED", "studentId", studentId, "problemId", problemId)
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

    public void notifyProblemMatched(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/tutor/" + tutorId,
                Map.of("type", "PROBLEM_MATCHED", "problemId", problemId)
        );
    }

    public void notifyNewProblem(Long problemId) {
        messagingTemplate.convertAndSend(
                "/topic/new-problem",
                Map.of("type", "NEW_PROBLEM", "problemId", problemId)
        );
    }

    public void notifyMatchRequested(Long problemId, Long tutorId, Long studentId) {
        Map<String, Object> tutorPayload = new HashMap<>();
        tutorPayload.put("type", "MATCH_REQUESTED");
        tutorPayload.put("problemId", problemId);
        tutorPayload.put("tutorId", tutorId);
        tutorPayload.put("studentId", studentId);
        tutorPayload.put("message", "매칭 요청이 왔습니다. 지금 바로 강의를 시작하시겠습니까?");

        Map<String, Object> studentPayload = new HashMap<>();
        studentPayload.put("type", "MATCH_REQUESTED");
        studentPayload.put("problemId", problemId);
        studentPayload.put("tutorId", tutorId);
        studentPayload.put("studentId", studentId);
        studentPayload.put("message", "매칭된 강사가 있습니다. 지금 바로 강의를 시작하시겠습니까?");

        messagingTemplate.convertAndSend("/topic/tutor/" + tutorId, tutorPayload);
        messagingTemplate.convertAndSend("/topic/student/" + studentId, studentPayload);
    }

    public void notifyMatchCancelled(Long problemId, Long tutorId, Long studentId, String cancelledBy) {
        String tutorMsg;
        String studentMsg;
        switch (cancelledBy) {
            case "tutor" -> {
                tutorMsg   = "강의를 취소하셨습니다.";
                studentMsg = "상대방이 강의를 취소하셨습니다.";
            }
            case "student" -> {
                tutorMsg   = "상대방이 강의를 취소하셨습니다.";
                studentMsg = "강의를 취소하셨습니다.";
            }
            case "timeout_tutor" -> {
                tutorMsg   = "응답하지 않아 강의가 취소되었습니다.";
                studentMsg = "상대방이 응답하지 않아 강의가 취소되었습니다.";
            }
            default -> {
                tutorMsg   = "상대방이 응답하지 않아 강의가 취소되었습니다.";
                studentMsg = "응답하지 않아 강의가 취소되었습니다.";
            }
        }

        messagingTemplate.convertAndSend("/topic/tutor/" + tutorId,
                Map.of("type", "MATCH_CANCELLED", "problemId", problemId, "message", tutorMsg));
        messagingTemplate.convertAndSend("/topic/student/" + studentId,
                Map.of("type", "MATCH_CANCELLED", "problemId", problemId, "message", studentMsg));
    }
}
