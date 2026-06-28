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

    public void notifyTutorCancelled(Long problemId, Long tutorId, Long studentId) {
        messagingTemplate.convertAndSend(
                "/topic/student/" + studentId,
                Map.of("type", "TUTOR_CANCELLED", "problemId", problemId, "tutorId", tutorId)
        );
    }

    public void notifyMatched(Long problemId, Long tutorId, Long studentId, Long lessonId, String channelName, List<String> imageUrls, String subject, String tutorProfileImageUrl, String studentProfileImageUrl) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "MATCHED");
        payload.put("tutorId", tutorId);
        payload.put("studentId", studentId);
        payload.put("problemId", problemId);
        payload.put("lessonId", lessonId);
        payload.put("channelName", channelName);
        payload.put("imageUrls", imageUrls);
        payload.put("subject", subject);
        payload.put("tutorProfileImageUrl", tutorProfileImageUrl);
        payload.put("studentProfileImageUrl", studentProfileImageUrl);
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

    /** 수업 시작 → 학생 화면 '수업 중' 표시(선택 차단). (온/오프 토글과 구분됨) */
    public void notifyTutorUnavailable(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/matching/" + problemId,
                Map.of("type", "TUTOR_UNAVAILABLE", "tutorId", tutorId, "problemId", problemId)
        );
    }

    /** 수업 종료 → '수업 중' 해제. */
    public void notifyTutorAvailable(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/matching/" + problemId,
                Map.of("type", "TUTOR_AVAILABLE", "tutorId", tutorId, "problemId", problemId)
        );
    }

    /** 강사가 온라인 전환 → 학생 화면 온라인 배지. (수업중 여부와 별개) */
    public void notifyTutorOnline(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/matching/" + problemId,
                Map.of("type", "TUTOR_ONLINE", "tutorId", tutorId, "problemId", problemId)
        );
    }

    /** 강사가 오프라인 전환 → 학생 화면 오프라인 배지. */
    public void notifyTutorOffline(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/matching/" + problemId,
                Map.of("type", "TUTOR_OFFLINE", "tutorId", tutorId, "problemId", problemId)
        );
    }

    public void notifyProblemMatched(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/tutor/" + tutorId,
                Map.of("type", "PROBLEM_MATCHED", "problemId", problemId)
        );
    }

    public void notifyProblemCancelled(Long problemId, Long tutorId) {
        messagingTemplate.convertAndSend(
                "/topic/tutor/" + tutorId,
                Map.of("type", "PROBLEM_CANCELLED", "problemId", problemId)
        );
    }

    public void notifyNewProblem(Long problemId) {
        messagingTemplate.convertAndSend(
                "/topic/new-problem",
                Map.of("type", "NEW_PROBLEM", "problemId", problemId)
        );
    }

    /** 문제가 취소/종료되어 더 이상 탐색 대상이 아님 → 모든 강사 리스트에서 즉시 제거. */
    public void notifyProblemRemoved(Long problemId) {
        messagingTemplate.convertAndSend(
                "/topic/new-problem",
                Map.of("type", "PROBLEM_REMOVED", "problemId", problemId)
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
                tutorMsg   = "매칭을 취소했어요.";
                studentMsg = "상대방이 매칭을 취소했어요.";
            }
            case "student" -> {
                tutorMsg   = "상대방이 매칭을 취소했어요.";
                studentMsg = "매칭을 취소했어요.";
            }
            case "timeout_tutor" -> {
                tutorMsg   = "시간 내 응답하지 않아 매칭이 취소됐어요.";
                studentMsg = "상대방이 응답하지 않아 매칭이 취소됐어요.";
            }
            default -> {
                tutorMsg   = "상대방이 응답하지 않아 매칭이 취소됐어요.";
                studentMsg = "시간 내 응답하지 않아 매칭이 취소됐어요.";
            }
        }

        messagingTemplate.convertAndSend("/topic/tutor/" + tutorId,
                Map.of("type", "MATCH_CANCELLED", "problemId", problemId, "tutorId", tutorId, "message", tutorMsg));
        messagingTemplate.convertAndSend("/topic/student/" + studentId,
                Map.of("type", "MATCH_CANCELLED", "problemId", problemId, "tutorId", tutorId, "message", studentMsg));
    }
}
