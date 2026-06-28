package com.ieum.backend.domain.lessonreview.service;

import com.ieum.backend.domain.lessonreview.repository.LessonQueryRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonTranscriptRepository;
import com.ieum.backend.global.agora.AgoraRecordingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 트랜스크립트 추출 + PDF 학습 자료 생성 폴링 잡.
 * 한 폴링 사이클에서:
 *   0) recording_url 누락 강의 → S3에서 mp4 재탐색해 채움
 *   1) 전사 미완료 강의 → 트랜스크립트 추출
 *   2) 전사 완료 + PDF 미완료 + problem_id·이미지 존재 강의 → PDF 생성
 *
 * fixedDelay — 이전 실행 끝난 뒤에 다음 실행 (동시 실행 방지).
 * initialDelay 30초 — 서버 부팅 직후 폴링을 잠시 지연.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TranscriptScheduler {

    private final LessonQueryRepository lessonQueryRepository;
    private final LessonTranscriptRepository lessonTranscriptRepository;
    private final TranscriptService transcriptService;
    private final LessonSummaryService lessonSummaryService;
    private final AgoraRecordingService agoraRecordingService;

    @Scheduled(
            fixedDelayString = "${transcript.polling-interval-ms:300000}",
            initialDelay = 30000
    )
    public void pollAndProcess() {
        // 0) recording_url 누락 복구 — S3에 mp4가 생겼으면 채운다 (재시작/늦은 mp4 대비)
        List<Long> needsUrl = lessonQueryRepository.findCompletedLessonIdsWithoutRecordingUrl();
        for (Long lessonId : needsUrl) {
            String mp4Url = agoraRecordingService.resolveRecordingMp4Url(lessonId);
            if (mp4Url != null) {
                lessonQueryRepository.updateRecordingUrl(lessonId, mp4Url);
                log.info("[TranscriptScheduler] mp4 재탐색→recording_url 채움 - lessonId={}, url={}", lessonId, mp4Url);
            }
        }

        // 1) 전사 처리
        List<Long> needsTranscript = lessonQueryRepository.findCompletedLessonIdsWithoutTranscript();
        if (!needsTranscript.isEmpty()) {
            log.info("[TranscriptScheduler] 전사 대상 {}건: {}", needsTranscript.size(), needsTranscript);
            for (Long lessonId : needsTranscript) {
                try {
                    transcriptService.processLesson(lessonId);
                } catch (Exception e) {
                    log.error("[TranscriptScheduler] 전사 강의 {} 처리 중 예외 — 다음 강의로 진행", lessonId, e);
                }
            }
        }

        // 2) PDF 처리
        List<Long> needsPdf = lessonTranscriptRepository.findLessonIdsNeedingSummaryPdf();
        if (!needsPdf.isEmpty()) {
            log.info("[TranscriptScheduler] PDF 대상 {}건: {}", needsPdf.size(), needsPdf);
            for (Long lessonId : needsPdf) {
                try {
                    lessonSummaryService.generateAndUpload(lessonId);
                } catch (Exception e) {
                    log.error("[TranscriptScheduler] PDF 강의 {} 처리 중 예외 — 다음 강의로 진행", lessonId, e);
                }
            }
        }

        if (needsTranscript.isEmpty() && needsPdf.isEmpty()) {
            log.debug("[TranscriptScheduler] 처리 대기 강의 없음");
        }
    }
}