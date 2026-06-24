package com.ieum.backend.domain.aitutor.service;

import com.ieum.backend.domain.aitutor.controller.CreateSessionResponse;
import com.ieum.backend.domain.aitutor.controller.MessageItemResponse;
import com.ieum.backend.domain.aitutor.controller.SendMessageResponse;
import com.ieum.backend.domain.aitutor.controller.SessionListItemResponse;
import com.ieum.backend.domain.aitutor.entity.AiTutorMessage;
import com.ieum.backend.domain.aitutor.entity.AiTutorMessageRole;
import com.ieum.backend.domain.aitutor.entity.AiTutorSession;
import com.ieum.backend.domain.aitutor.entity.AiTutorSessionStatus;
import com.ieum.backend.domain.aitutor.repository.AiTutorMessageRepository;
import com.ieum.backend.domain.aitutor.repository.AiTutorSessionRepository;
import com.ieum.backend.domain.aitutor.repository.ProblemQueryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiTutorService {

    private final AiTutorSessionRepository sessionRepository;
    private final AiTutorMessageRepository messageRepository;
    private final ProblemQueryRepository problemQueryRepository;
    private final GeminiPromptBuilder promptBuilder;
    private final GeminiClient geminiClient;

    @Transactional
    public CreateSessionResponse createSession(Long studentId, Long problemId) {
        ProblemContext context = problemQueryRepository
                .findContextByIdAndStudentId(problemId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, AiTutorMessages.PROBLEM_NOT_FOUND));

        AiTutorSession session = AiTutorSession.builder()
                .studentId(studentId)
                .problemId(problemId)
                .title(buildTitle(context))
                .build();
        sessionRepository.save(session);

        return new CreateSessionResponse(
                session.getId(),
                session.getProblemId(),
                session.getTitle(),
                session.getStatus().name(),
                session.getCreatedAt()
        );
    }

    @Transactional
    public SendMessageResponse sendMessage(Long studentId, Long sessionId, String content) {
        AiTutorSession session = sessionRepository.findByIdAndStudentId(sessionId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, AiTutorMessages.SESSION_NOT_FOUND));

        if (session.getStatus() == AiTutorSessionStatus.CLOSED) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, AiTutorMessages.SESSION_CLOSED);
        }

        // 1) 학생 메시지 저장
        AiTutorMessage userMessage = AiTutorMessage.builder()
                .session(session)
                .role(AiTutorMessageRole.USER)
                .content(content)
                .build();
        messageRepository.save(userMessage);

        // 2) 문제 컨텍스트 → 시스템 지시문
        ProblemContext context = problemQueryRepository
                .findContextByIdAndStudentId(session.getProblemId(), studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, AiTutorMessages.SESSION_PROBLEM_NOT_FOUND));
        String systemInstruction = promptBuilder.buildSystemInstruction(context);

        // 3) 전체 히스토리(방금 저장한 학생 메시지 포함)로 Gemini 호출
        List<AiTutorMessage> history = messageRepository.findBySessionIdOrderByIdAsc(sessionId);

        // 4) Gemini 호출 — 실패하면 fallback 메시지로 대체
        String aiText;
        try {
            aiText = geminiClient.generate(systemInstruction, history);
        } catch (Exception e) {
            log.error("Gemini 호출 최종 실패. fallback 메시지로 응답합니다.", e);
            aiText = AiTutorMessages.GEMINI_FALLBACK;
        }

        // 4) AI 응답 저장
        AiTutorMessage aiMessage = AiTutorMessage.builder()
                .session(session)
                .role(AiTutorMessageRole.AI)
                .content(aiText)
                .build();
        messageRepository.save(aiMessage);

        return new SendMessageResponse(
                aiMessage.getId(),
                aiMessage.getRole().name(),
                aiMessage.getContent(),
                aiMessage.getCreatedAt()
        );
    }

    @Transactional(readOnly = true)
    public List<SessionListItemResponse> listSessions(Long studentId) {
        return sessionRepository.findByStudentIdOrderByUpdatedAtDesc(studentId)
                .stream()
                .map(s -> new SessionListItemResponse(
                        s.getId(),
                        s.getProblemId(),
                        s.getTitle(),
                        s.getStatus().name(),
                        s.getCreatedAt(),
                        s.getUpdatedAt()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<MessageItemResponse> getMessages(Long studentId, Long sessionId) {
        // 소유권 검증 — 남의 세션 메시지는 못 보게
        sessionRepository.findByIdAndStudentId(sessionId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, AiTutorMessages.SESSION_NOT_FOUND));

        return messageRepository.findBySessionIdOrderByIdAsc(sessionId)
                .stream()
                .map(m -> new MessageItemResponse(
                        m.getId(),
                        m.getRole().name(),
                        m.getContent(),
                        m.getCreatedAt()))
                .toList();
    }
    @Transactional
    public void closeSession(Long studentId, Long sessionId) {
        AiTutorSession session = sessionRepository.findByIdAndStudentId(sessionId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, AiTutorMessages.SESSION_NOT_FOUND));
        session.close();
    }

    private String buildTitle(ProblemContext context) {
        if (context.summary() != null && !context.summary().isBlank()) {
            String summary = context.summary().strip();
            return summary.length() > 30 ? summary.substring(0, 30) + "..." : summary;
        }
        return "AI 튜터 학습";
    }
}