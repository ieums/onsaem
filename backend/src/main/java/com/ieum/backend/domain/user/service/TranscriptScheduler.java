package com.ieum.backend.domain.user.service;

import com.ieum.backend.domain.user.repository.LessonQueryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 트랜스크립트 추출 폴링 잡.
 * fixedDelay — 이전 실행 끝난 뒤에 다음 실행 시작 (동시 실행 방지).
 * initialDelay 30초 — 서버 부팅 직후 폴링을 잠시 지연.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TranscriptScheduler {

    private final LessonQueryRepository lessonQueryRepository;
    private final TranscriptService transcriptService;

    @Scheduled(
            fixedDelayString = "${transcript.polling-interval-ms:300000}",
            initialDelay = 30000
    )
    public void pollAndProcess() {
        List<Long> lessonIds = lessonQueryRepository.findCompletedLessonIdsWithoutTranscript();
        if (lessonIds.isEmpty()) {
            log.debug("[TranscriptScheduler] 처리 대기 강의 없음");
            return;
        }
        log.info("[TranscriptScheduler] 처리 대상 강의 {}건: {}", lessonIds.size(), lessonIds);

        for (Long lessonId : lessonIds) {
            try {
                transcriptService.processLesson(lessonId);
            } catch (Exception e) {
                log.error("[TranscriptScheduler] 강의 {} 처리 중 예외 — 다음 강의로 진행", lessonId, e);
            }
        }
    }
}