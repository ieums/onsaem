package com.ieum.backend.domain.lesson.scheduler;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.lesson.service.LessonService;
import com.ieum.backend.domain.matching.service.MatchingService;
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
    private final MatchingService matchingService;

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
                    restoreTutorAvailability(lesson.getTutorId());
                    deleteTempImagesQuietly(lesson.getId());
                });
    }

    private void cleanupStaleWaiting() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(24);
        lessonRepository.findByStatusAndCreatedAtBefore(Lesson.LessonStatus.WAITING, threshold)
                .forEach(lesson -> {
                    // 시작되지 못하고 방치된(튕김 등) 강의를 취소 처리해야
                    // '수업중'(ACTIVE/WAITING) 판정에서 빠져 강사 상태가 풀린다.
                    lesson.cancel();
                    restoreTutorAvailability(lesson.getTutorId());
                    deleteTempImagesQuietly(lesson.getId());
                });
    }

    /**
     * 비정상 종료로 남은 강사의 UNAVAILABLE 신청을 PENDING으로 복구한다.
     * 이게 안 풀리면 강사가 '수업 중'으로 묶여 새 문제에 신청조차 못 한다(MatchingService.apply).
     */
    private void restoreTutorAvailability(Long tutorId) {
        if (tutorId == null) return;
        try {
            matchingService.tutorEndLesson(tutorId);
        } catch (Exception e) {
            log.warn("[LessonScheduler] 강사 상태 복구 실패(무시하고 진행). tutorId={}, cause={}",
                    tutorId, e.getMessage());
        }
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
