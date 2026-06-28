package com.ieum.backend.domain.lesson.scheduler;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.lesson.service.LessonService;
import com.ieum.backend.global.s3.S3Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
public class LessonScheduler {

    private final LessonRepository lessonRepository;
    private final S3Service s3Service;
    private final LessonService lessonService;

    @Scheduled(fixedDelay = 3600000)
    @Transactional
    public void run() {
        cleanupStaleActive();
        cleanupStaleWaiting();
    }

    /** 정산 확정(24h 보류 후 미신고 건). 별도 트랜잭션이라 run()과 분리. */
    @Scheduled(fixedDelay = 600000) // 10분마다
    public void settleDue() {
        lessonService.finalizeDueSettlements();
    }

    private void cleanupStaleActive() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(24);
        lessonRepository.findByStatusAndStartedAtBefore(Lesson.LessonStatus.ACTIVE, threshold)
                .forEach(lesson -> {
                    lesson.complete(null);
                    deleteTempImagesQuietly(lesson.getId());
                });
    }

    private void cleanupStaleWaiting() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(24);
        lessonRepository.findByStatusAndCreatedAtBefore(Lesson.LessonStatus.WAITING, threshold)
                .forEach(lesson -> deleteTempImagesQuietly(lesson.getId()));
    }

    /**
     * 임시 이미지 정리는 best-effort.
     * S3 실패(자격증명 오류·네트워크 등)가 스케줄러 전체를 죽이거나
     * (@Transactional run()의) stale 강의 정리를 롤백시키면 안 되므로 삼켜서 로깅만 한다.
     */
    private void deleteTempImagesQuietly(Long lessonId) {
        try {
            s3Service.deleteTempImages(lessonId);
        } catch (Exception e) {
            log.warn("[LessonScheduler] 임시 이미지 정리 실패(무시하고 진행). lessonId={}, cause={}",
                    lessonId, e.getMessage());
        }
    }
}
