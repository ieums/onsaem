package com.ieum.backend.domain.lessonreview.service;

import com.ieum.backend.domain.aitutor.entity.AiTutorMessage;
import com.ieum.backend.domain.aitutor.entity.AiTutorMessageRole;
import com.ieum.backend.domain.aitutor.service.GeminiClient;
import com.ieum.backend.domain.lessonreview.controller.CreateReviewSessionResponse;
import com.ieum.backend.domain.lessonreview.controller.ReviewMessageItemResponse;
import com.ieum.backend.domain.lessonreview.controller.ReviewSessionListItemResponse;
import com.ieum.backend.domain.lessonreview.controller.SendReviewMessageResponse;
import com.ieum.backend.domain.lessonreview.entity.LessonReviewMessage;
import com.ieum.backend.domain.lessonreview.entity.LessonReviewMessageRole;
import com.ieum.backend.domain.lessonreview.entity.LessonReviewSession;
import com.ieum.backend.domain.lessonreview.entity.LessonReviewSessionStatus;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscript;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscriptStatus;
import com.ieum.backend.domain.lessonreview.repository.LessonQueryRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonReviewMessageRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonReviewSessionRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonTranscriptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.ieum.backend.domain.lessonreview.controller.SummaryPdfResponse;
import com.ieum.backend.domain.lessonreview.entity.LessonSummaryPdfStatus;

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
    private final LessonSummaryService lessonSummaryService;

    private final GeminiClient geminiClient;

    // ─────────────────────────────────────────
    // 1. 세션 생성
    // ─────────────────────────────────────────
    @Transactional
    public CreateReviewSessionResponse createSession(Long studentId, Long lessonId) {
        LessonInfo lesson = lessonQueryRepository.findByIdAndStudentId(lessonId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, LessonReviewMessages.LESSON_NOT_FOUND));

        LessonTranscript transcript = lessonTranscriptRepository.findByLessonId(lessonId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, LessonReviewMessages.TRANSCRIPT_NOT_READY));

        if (transcript.getStatus() != LessonTranscriptStatus.COMPLETED) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    String.format(LessonReviewMessages.TRANSCRIPT_PROCESSING_TEMPLATE, transcript.getStatus()));
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
                        HttpStatus.NOT_FOUND, LessonReviewMessages.SESSION_NOT_FOUND));

        if (session.getStatus() == LessonReviewSessionStatus.CLOSED) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, LessonReviewMessages.SESSION_CLOSED);
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
            aiText = LessonReviewMessages.GEMINI_FALLBACK;
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
                        HttpStatus.NOT_FOUND, LessonReviewMessages.SESSION_NOT_FOUND));

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
    // 5. PDF 학습 자료 다운로드 URL 조회
    // ─────────────────────────────────────────
    @Transactional(readOnly = true)
    public SummaryPdfResponse getSummaryPdf(Long studentId, Long lessonId) {
        // 강의 소유권 검증
        lessonQueryRepository.findByIdAndStudentId(lessonId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, LessonReviewMessages.LESSON_NOT_FOUND));

        LessonTranscript transcript = lessonTranscriptRepository.findByLessonId(lessonId).orElse(null);
        if (transcript == null) {
            return new SummaryPdfResponse("NOT_READY", null,
                    LessonReviewMessages.TRANSCRIPT_NOT_READY);
        }

        LessonSummaryPdfStatus status = transcript.getSummaryPdfStatus();
        if (status == LessonSummaryPdfStatus.COMPLETED && transcript.getSummaryPdfUrl() != null) {
            String presignedUrl = lessonSummaryService.generatePresignedUrl(transcript.getSummaryPdfUrl());
            return new SummaryPdfResponse("COMPLETED", presignedUrl, LessonReviewMessages.PDF_READY);
        }
        if (status == LessonSummaryPdfStatus.PROCESSING) {
            return new SummaryPdfResponse("PROCESSING", null,
                    LessonReviewMessages.PDF_PROCESSING);
        }
        if (status == LessonSummaryPdfStatus.FAILED) {
            return new SummaryPdfResponse("FAILED", null,
                    LessonReviewMessages.PDF_FAILED);
        }
        // status == null (PENDING) 이거나 데이터 부족 등으로 처리 안 시작된 경우
        return new SummaryPdfResponse("NOT_READY", null,
                LessonReviewMessages.PDF_NOT_READY);
    }

    // ─────────────────────────────────────────
    // 내부 헬퍼
    // ─────────────────────────────────────────

    private LessonContext buildLessonContext(Long lessonId, Long studentId) {
        LessonInfo lesson = lessonQueryRepository.findByIdAndStudentId(lessonId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, LessonReviewMessages.LESSON_NOT_FOUND_FOR_SESSION));

        LessonTranscript transcript = lessonTranscriptRepository.findByLessonId(lessonId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, LessonReviewMessages.TRANSCRIPT_NOT_READY));

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
            return lesson.startedAt().format(TITLE_FMT) + LessonReviewMessages.SESSION_TITLE_SUFFIX;
        }
        return LessonReviewMessages.SESSION_TITLE_DEFAULT;
    }

    /**
     * Gemini 호출 시 AiTutorMessage 리스트가 필요한데,
     * 복습 챗봇은 LessonReviewMessage 를 쓰므로 어댑팅.
     * (GeminiClient가 AiTutorMessage 타입을 받게 만들어 놨음 — 같은 모양이라 변환만 하면 됨)
     */
    private List<AiTutorMessage> toAiTutorMessages(List<LessonReviewMessage> history) {
        return history.stream()
                .map(m -> AiTutorMessage.builder()
                        .role(m.getRole() == LessonReviewMessageRole.USER
                                ? AiTutorMessageRole.USER
                                : AiTutorMessageRole.AI)
                        .content(m.getContent())
                        .build())
                .toList();
    }
}