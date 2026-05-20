package com.ieum.backend.domain.user.service;

import com.ieum.backend.domain.user.controller.CreateSessionResponse;
import com.ieum.backend.domain.user.controller.SendMessageResponse;
import com.ieum.backend.domain.user.entity.AiTutorMessage;
import com.ieum.backend.domain.user.entity.AiTutorMessageRole;
import com.ieum.backend.domain.user.entity.AiTutorSession;
import com.ieum.backend.domain.user.entity.AiTutorSessionStatus;
import com.ieum.backend.domain.user.repository.AiTutorMessageRepository;
import com.ieum.backend.domain.user.repository.AiTutorSessionRepository;
import com.ieum.backend.domain.user.repository.ProblemQueryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

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
                        HttpStatus.NOT_FOUND, "해당 문제를 찾을 수 없습니다."));

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
                        HttpStatus.NOT_FOUND, "세션을 찾을 수 없습니다."));

        if (session.getStatus() == AiTutorSessionStatus.CLOSED) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "이미 종료된 세션입니다.");
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
                        HttpStatus.NOT_FOUND, "세션에 연결된 문제를 찾을 수 없습니다."));
        String systemInstruction = promptBuilder.buildSystemInstruction(context);

        // 3) 전체 히스토리(방금 저장한 학생 메시지 포함)로 Gemini 호출
        List<AiTutorMessage> history = messageRepository.findBySessionIdOrderByIdAsc(sessionId);
        String aiText = geminiClient.generate(systemInstruction, history);

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

    private String buildTitle(ProblemContext context) {
        if (context.summary() != null && !context.summary().isBlank()) {
            String summary = context.summary().strip();
            return summary.length() > 30 ? summary.substring(0, 30) + "..." : summary;
        }
        return "AI 튜터 학습";
    }
}