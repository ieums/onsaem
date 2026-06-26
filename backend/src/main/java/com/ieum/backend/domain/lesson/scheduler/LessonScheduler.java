package com.ieum.backend.domain.lesson.scheduler;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.lesson.service.LessonService;
import com.ieum.backend.global.s3.S3Service;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

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
                    s3Service.deleteTempImages(lesson.getId());
                });
    }

    private void cleanupStaleWaiting() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(24);
        lessonRepository.findByStatusAndCreatedAtBefore(Lesson.LessonStatus.WAITING, threshold)
                .forEach(lesson -> s3Service.deleteTempImages(lesson.getId()));
    }
}
