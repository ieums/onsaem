package com.ieum.backend.domain.user.service;

import com.ieum.backend.domain.user.controller.CreateReviewSessionResponse;
import com.ieum.backend.domain.user.controller.ReviewMessageItemResponse;
import com.ieum.backend.domain.user.controller.ReviewSessionListItemResponse;
import com.ieum.backend.domain.user.controller.SendReviewMessageResponse;
import com.ieum.backend.domain.user.entity.LessonReviewMessage;
import com.ieum.backend.domain.user.entity.LessonReviewMessageRole;
import com.ieum.backend.domain.user.entity.LessonReviewSession;
import com.ieum.backend.domain.user.entity.LessonReviewSessionStatus;
import com.ieum.backend.domain.user.entity.LessonTranscript;
import com.ieum.backend.domain.user.entity.LessonTranscriptStatus;
import com.ieum.backend.domain.user.repository.LessonQueryRepository;
import com.ieum.backend.domain.user.repository.LessonReviewMessageRepository;
import com.ieum.backend.domain.user.repository.LessonReviewSessionRepository;
import com.ieum.backend.domain.user.repository.LessonTranscriptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.format.DateTimeFormatter;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class LessonReviewService {

    private static final DateTimeFormatter TITLE_FMT = DateTimeFormatter.ofPattern("M/d HH:mm");

    private final LessonReviewSessionRepository sessionRepository;
    private final LessonReviewMessageRepository messageRepository;
    private final LessonQueryRepository lessonQueryRepository;
    private final LessonTranscriptRepository lessonTranscriptRepository;
    private final LessonReviewPromptBuilder promptBuilder;
    private final GeminiClient geminiClient;

    // ─────────────────────────────────────────
    // 1. 세션 생성
    // ─────────────────────────────────────────
    @Transactional
    public CreateReviewSessionResponse createSession(Long studentId, Long lessonId) {
        LessonInfo lesson = lessonQueryRepository.findByIdAndStudentId(lessonId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "해당 강의를 찾을 수 없습니다."));

        LessonTranscript transcript = lessonTranscriptRepository.findByLessonId(lessonId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "복습 자료가 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요."));

        if (transcript.getStatus() != LessonTranscriptStatus.COMPLETED) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "복습 자료가 아직 준비 중입니다 (상태: " + transcript.getStatus() + "). 잠시 후 다시 시도해주세요.");
        }

        LessonReviewSession session = LessonReviewSession.builder()
                .studentId(studentId)
                .lessonId(lessonId)
                .title(buildTitle(lesson))
                .build();
        sessionRepository.save(session);

        return new CreateReviewSessionResponse(
                session.getId(),
                session.getLessonId(),
                session.getTitle(),
                session.getStatus().name(),
                session.getCreatedAt()
        );
    }

    // ─────────────────────────────────────────
    // 2. 메시지 전송
    // ─────────────────────────────────────────
    @Transactional
    public SendReviewMessageResponse sendMessage(Long studentId, Long sessionId, String content) {
        LessonReviewSession session = sessionRepository.findByIdAndStudentId(sessionId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "세션을 찾을 수 없습니다."));

        if (session.getStatus() == LessonReviewSessionStatus.CLOSED) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "이미 종료된 세션입니다.");
        }

        // 1) 학생 메시지 저장
        LessonReviewMessage userMessage = LessonReviewMessage.builder()
                .session(session)
                .role(LessonReviewMessageRole.USER)
                .content(content)
                .build();
        messageRepository.save(userMessage);

        // 2) 강의 정보 + 트랜스크립트 → 시스템 프롬프트
        LessonContext context = buildLessonContext(session.getLessonId(), studentId);
        String systemInstruction = promptBuilder.buildSystemInstruction(context);

        // 3) 히스토리 전체로 Gemini 호출 (방금 저장한 user 메시지 포함)
        List<LessonReviewMessage> history = messageRepository.findBySessionIdOrderByIdAsc(sessionId);

        // 4) Gemini 호출 — 실패해도 fallback 메시지로 응답
        String aiText;
        try {
            aiText = geminiClient.generate(systemInstruction, toAiTutorMessages(history));
        } catch (Exception e) {
            log.error("[LessonReview] Gemini 호출 실패. fallback 메시지로 응답.", e);
            aiText = "AI 튜터가 잠시 응답할 수 없어요. 잠시 후 다시 질문해주세요.";
        }

        // 5) AI 응답 저장
        LessonReviewMessage aiMessage = LessonReviewMessage.builder()
                .session(session)
                .role(LessonReviewMessageRole.AI)
                .content(aiText)
                .build();
        messageRepository.save(aiMessage);

        session.touch();

        return new SendReviewMessageResponse(
                aiMessage.getId(),
                aiMessage.getRole().name(),
                aiMessage.getContent(),
                aiMessage.getCreatedAt()
        );
    }

    // ─────────────────────────────────────────
    // 3. 세션 목록
    // ─────────────────────────────────────────
    @Transactional(readOnly = true)
    public List<ReviewSessionListItemResponse> listSessions(Long studentId) {
        return sessionRepository.findByStudentIdOrderByUpdatedAtDesc(studentId)
                .stream()
                .map(s -> new ReviewSessionListItemResponse(
                        s.getId(),
                        s.getLessonId(),
                        s.getTitle(),
                        s.getStatus().name(),
                        s.getCreatedAt(),
                        s.getUpdatedAt()))
                .toList();
    }

    // ─────────────────────────────────────────
    // 4. 메시지 히스토리
    // ─────────────────────────────────────────
    @Transactional(readOnly = true)
    public List<ReviewMessageItemResponse> getMessages(Long studentId, Long sessionId) {
        sessionRepository.findByIdAndStudentId(sessionId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "세션을 찾을 수 없습니다."));

        return messageRepository.findBySessionIdOrderByIdAsc(sessionId)
                .stream()
                .map(m -> new ReviewMessageItemResponse(
                        m.getId(),
                        m.getRole().name(),
                        m.getContent(),
                        m.getCreatedAt()))
                .toList();
    }

    // ─────────────────────────────────────────
    // 내부 헬퍼
    // ─────────────────────────────────────────

    private LessonContext buildLessonContext(Long lessonId, Long studentId) {
        LessonInfo lesson = lessonQueryRepository.findByIdAndStudentId(lessonId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "세션에 연결된 강의를 찾을 수 없습니다."));

        LessonTranscript transcript = lessonTranscriptRepository.findByLessonId(lessonId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "복습 자료가 아직 준비되지 않았습니다."));

        return new LessonContext(
                lesson.lessonId(),
                lesson.tutorId(),
                lesson.startedAt(),
                lesson.endedAt(),
                transcript.getTranscript(),
                transcript.getSummary()
        );
    }

    private String buildTitle(LessonInfo lesson) {
        if (lesson.startedAt() != null) {
            return lesson.startedAt().format(TITLE_FMT) + " 수업 복습";
        }
        return "강의 복습";
    }

    /**
     * Gemini 호출 시 AiTutorMessage 리스트가 필요한데,
     * 복습 챗봇은 LessonReviewMessage 를 쓰므로 어댑팅.
     * (GeminiClient가 AiTutorMessage 타입을 받게 만들어 놨음 — 같은 모양이라 변환만 하면 됨)
     */
    private List<com.ieum.backend.domain.user.entity.AiTutorMessage> toAiTutorMessages(List<LessonReviewMessage> history) {
        return history.stream()
                .map(m -> com.ieum.backend.domain.user.entity.AiTutorMessage.builder()
                        .role(m.getRole() == LessonReviewMessageRole.USER
                                ? com.ieum.backend.domain.user.entity.AiTutorMessageRole.USER
                                : com.ieum.backend.domain.user.entity.AiTutorMessageRole.AI)
                        .content(m.getContent())
                        .build())
                .toList();
    }
}