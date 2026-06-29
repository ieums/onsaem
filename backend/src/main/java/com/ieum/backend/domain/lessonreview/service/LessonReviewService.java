package com.ieum.backend.domain.lessonreview.service;

import com.ieum.backend.domain.aitutor.entity.AiTutorMessage;
import com.ieum.backend.domain.aitutor.entity.AiTutorMessageRole;
import com.ieum.backend.domain.aitutor.service.GeminiClient;
import com.ieum.backend.domain.lessonreview.controller.CreateReviewSessionResponse;
import com.ieum.backend.domain.lessonreview.controller.ReviewLessonItemResponse;
import com.ieum.backend.domain.lessonreview.controller.ReviewMessageItemResponse;
import com.ieum.backend.domain.lessonreview.controller.ReviewSessionListItemResponse;
import com.ieum.backend.domain.lessonreview.controller.SendReviewMessageResponse;
import com.ieum.backend.domain.lessonreview.controller.SummaryPdfResponse;
import com.ieum.backend.domain.lessonreview.entity.LessonReviewMessage;
import com.ieum.backend.domain.lessonreview.entity.LessonReviewMessageRole;
import com.ieum.backend.domain.lessonreview.entity.LessonReviewSession;
import com.ieum.backend.domain.lessonreview.entity.LessonReviewSessionStatus;
import com.ieum.backend.domain.lessonreview.entity.LessonSummaryPdfStatus;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscript;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscriptStatus;
import com.ieum.backend.domain.lessonreview.repository.LessonQueryRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonReviewMessageRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonReviewSessionRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonTranscriptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

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
    private final LessonMediaStorage lessonMediaStorage;
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

        LessonReviewMessage userMessage = LessonReviewMessage.builder()
                .session(session)
                .role(LessonReviewMessageRole.USER)
                .content(content)
                .build();
        messageRepository.save(userMessage);

        LessonContext context = buildLessonContext(session.getLessonId(), studentId);
        String systemInstruction = promptBuilder.buildSystemInstruction(context);

        List<LessonReviewMessage> history = messageRepository.findBySessionIdOrderByIdAsc(sessionId);

        String aiText;
        try {
            aiText = geminiClient.generate(systemInstruction, toAiTutorMessages(history));
        } catch (Exception e) {
            log.error("[LessonReview] Gemini 호출 실패. fallback 메시지로 응답.", e);
            aiText = LessonReviewMessages.GEMINI_FALLBACK;
        }

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

    /**
     * 복습 목록 (A+B): 완료된 강의를 모두 내려준다.
     * 전사 완료 전이면 ready=false("복습 준비중"), 완료되면 ready=true(진입 가능).
     * 진입 시 세션을 만들면 되므로 여기서 세션을 미리 만들진 않는다.
     */
    public List<ReviewLessonItemResponse> listReviewLessons(Long studentId) {
        List<LessonInfo> lessons = lessonQueryRepository.findCompletedLessonsByStudentId(studentId);
        if (lessons.isEmpty()) {
            return List.of();
        }

        List<Long> lessonIds = lessons.stream().map(LessonInfo::lessonId).toList();

        Map<Long, LessonTranscriptStatus> transcriptStatus = lessonTranscriptRepository
                .findByLessonIdIn(lessonIds).stream()
                .collect(Collectors.toMap(LessonTranscript::getLessonId, LessonTranscript::getStatus));

        Map<Long, Long> sessionByLesson = sessionRepository
                .findByStudentIdOrderByUpdatedAtDesc(studentId).stream()
                .collect(Collectors.toMap(
                        LessonReviewSession::getLessonId,
                        LessonReviewSession::getId,
                        (a, b) -> a)); // 같은 강의에 세션 여러 개면 최신(updatedAt desc 정렬 첫 번째) 사용

        Map<Long, String> subjectByLesson =
                lessonQueryRepository.findSubjectsByLessonIds(lessonIds);
        Map<Long, String> imageByLesson =
                lessonQueryRepository.findFirstImageUrlByLessonIds(lessonIds);

        return lessons.stream()
                .map(lesson -> {
                    boolean ready = transcriptStatus.get(lesson.lessonId()) == LessonTranscriptStatus.COMPLETED;
                    return new ReviewLessonItemResponse(
                            lesson.lessonId(),
                            buildTitle(lesson),
                            ready,
                            ready ? "READY" : "PREPARING",
                            sessionByLesson.get(lesson.lessonId()),
                            lesson.endedAt(),
                            subjectByLesson.get(lesson.lessonId()),
                            imageByLesson.get(lesson.lessonId()));
                })
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
    // 5. PDF + 영상 URL 조회
    // ─────────────────────────────────────────
    @Transactional(readOnly = true)
    public SummaryPdfResponse getSummaryPdf(Long studentId, Long lessonId) {
        LessonInfo lesson = lessonQueryRepository.findByIdAndStudentId(lessonId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, LessonReviewMessages.LESSON_NOT_FOUND));

        // raw 경로 대신 '재생 URL'(local=인증 엔드포인트, prod=presigned)로 변환
        String recordingUrl = (lesson.recordingUrl() == null) ? null
                : lessonMediaStorage.recordingPlaybackUrl(lessonId, lesson.recordingUrl());

        LessonTranscript transcript = lessonTranscriptRepository.findByLessonId(lessonId).orElse(null);
        if (transcript == null) {
            return new SummaryPdfResponse("NOT_READY", null,
                    LessonReviewMessages.TRANSCRIPT_NOT_READY, recordingUrl);
        }

        LessonSummaryPdfStatus status = transcript.getSummaryPdfStatus();
        if (status == LessonSummaryPdfStatus.COMPLETED && transcript.getSummaryPdfUrl() != null) {
            String presignedUrl = lessonSummaryService.generatePresignedUrl(transcript.getSummaryPdfUrl());
            return new SummaryPdfResponse("COMPLETED", presignedUrl,
                    LessonReviewMessages.PDF_READY, recordingUrl);
        }
        if (status == LessonSummaryPdfStatus.PROCESSING) {
            return new SummaryPdfResponse("PROCESSING", null,
                    LessonReviewMessages.PDF_PROCESSING, recordingUrl);
        }
        if (status == LessonSummaryPdfStatus.FAILED) {
            return new SummaryPdfResponse("FAILED", null,
                    LessonReviewMessages.PDF_FAILED, recordingUrl);
        }
        return new SummaryPdfResponse("NOT_READY", null,
                LessonReviewMessages.PDF_NOT_READY, recordingUrl);
    }

    // ─────────────────────────────────────────
    // 6. 녹음 스트리밍 (소유권 체크) — local 전용 경로
    // ─────────────────────────────────────────
    @Transactional(readOnly = true)
    public Resource getRecordingResource(Long studentId, Long lessonId) {
        LessonInfo lesson = lessonQueryRepository.findByIdAndStudentId(lessonId, studentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, LessonReviewMessages.LESSON_NOT_FOUND));
        if (lesson.recordingUrl() == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "녹음이 없습니다.");
        }
        return lessonMediaStorage.openRecordingResource(lessonId, lesson.recordingUrl());
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