package com.ieum.backend.domain.lessonreview.service;

import com.ieum.backend.domain.aitutor.service.GeminiProperties;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscript;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscriptStatus;
import com.ieum.backend.domain.lessonreview.repository.LessonQueryRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonTranscriptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import com.ieum.backend.global.util.ClasspathLoader;

/**
 * 강의 영상 → 트랜스크립트 추출 흐름 조율.
 * S3 다운로드 → Gemini File API 업로드 → 전사 요청 → DB 저장.
 * Scheduler가 lesson 단위로 호출.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TranscriptService {

    private static final String TRANSCRIBE_PROMPT = ClasspathLoader.loadAsString("prompts/lesson-transcribe.md");

    private final LessonQueryRepository lessonQueryRepository;
    private final LessonTranscriptRepository lessonTranscriptRepository;
    private final LessonMediaStorage lessonMediaStorage;
    private final GeminiFileClient geminiFileClient;
    private final GeminiProperties geminiProperties;

    /**
     * 한 강의의 트랜스크립트를 추출해 DB에 저장.
     * 실패 시 LessonTranscript 행은 FAILED 상태로 마무리 — 다음 폴링에서 재시도 가능.
     */
    @Transactional
    public void processLesson(Long lessonId) {
        LessonInfo lesson = lessonQueryRepository.findById(lessonId).orElse(null);
        if (lesson == null) {
            log.warn("[Transcript] 강의 {} — lessons 테이블에서 못 찾음. 건너뜀.", lessonId);
            return;
        }
        if (lesson.recordingUrl() == null || lesson.recordingUrl().isBlank()) {
            log.warn("[Transcript] 강의 {} — recording_url 없음. 건너뜀.", lessonId);
            return;
        }

        // 녹음 파일이 아직 없으면(예: 로컬에 파일 미투입) 에러 없이 조용히 스킵.
        // 트랜스크립트 행을 만들지 않으므로 다음 폴링에서 파일이 생기면 자동 처리된다.
        if (!lessonMediaStorage.isRecordingAvailable(lessonId, lesson.recordingUrl())) {
            log.debug("[Transcript] 강의 {} — 녹음 파일 아직 없음. 조용히 스킵(다음 폴링 재시도).", lessonId);
            return;
        }

        log.info("[Transcript] 강의 {} 처리 시작", lessonId);

        LessonTranscript transcript = lessonTranscriptRepository.findByLessonId(lessonId)
                .orElseGet(() -> lessonTranscriptRepository.save(
                        LessonTranscript.builder().lessonId(lessonId).build()));

        if (transcript.getStatus() == LessonTranscriptStatus.COMPLETED) {
            log.info("[Transcript] 강의 {} 이미 완료. 스킵.", lessonId);
            return;
        }

        transcript.markProcessing();

        Path videoPath = null;
        String fileUri = null;
        try {
            videoPath = lessonMediaStorage.fetchRecordingToTemp(lessonId, lesson.recordingUrl());
            // 실제 파일 확장자에 맞는 MIME으로 업로드 (mp3를 video/mp4로 올리면 Gemini가 처리 실패).
            String mime = mimeOf(videoPath);
            log.info("[Transcript] 강의 {} 녹음 다운로드 완료: {} (mime={})", lessonId, videoPath, mime);

            fileUri = geminiFileClient.uploadAndWaitActive(videoPath, mime);
            log.info("[Transcript] 강의 {} Gemini 업로드/ACTIVE 완료: {}", lessonId, fileUri);

            String text = geminiFileClient.generateWithFile(
                    geminiProperties.model(), TRANSCRIBE_PROMPT, fileUri, mime);
            log.info("[Transcript] 강의 {} 전사 완료 (length={})", lessonId, text.length());

            transcript.markCompleted(text, null);

        } catch (Exception e) {
            log.error("[Transcript] 강의 {} 처리 실패", lessonId, e);
            transcript.markFailed(e.getMessage());
            // throw 안 함 — 트랜잭션 커밋해서 FAILED 영속화. 다음 폴링에서 재시도 가능.
        } finally {
            if (fileUri != null) {
                geminiFileClient.deleteFile(fileUri);    // ← Gemini 저장소에서 삭제(할당량 회수)
            }
            if (videoPath != null) {
                try { Files.deleteIfExists(videoPath); }
                catch (IOException ignored) { }
            }
        }
    }

    /** 파일 확장자 → Gemini 업로드용 MIME. (mp3 등 오디오를 video/mp4로 올리면 처리 실패) */
    private String mimeOf(Path path) {
        String name = path.getFileName().toString().toLowerCase();
        if (name.endsWith(".mp3")) return "audio/mpeg";
        if (name.endsWith(".m4a") || name.endsWith(".aac")) return "audio/mp4";
        if (name.endsWith(".wav")) return "audio/wav";
        if (name.endsWith(".ogg")) return "audio/ogg";
        if (name.endsWith(".webm")) return "video/webm";
        if (name.endsWith(".mp4")) return "video/mp4";
        return "audio/mpeg"; // 기본값(오디오)
    }
}