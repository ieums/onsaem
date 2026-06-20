package com.ieum.backend.domain.lesson.scheduler;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
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

    @Scheduled(fixedDelay = 3600000)
    @Transactional
    public void run() {
        cleanupStaleActive();
        cleanupStaleWaiting();
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
