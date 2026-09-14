package com.ieum.backend.domain.problem.scheduler;

import com.ieum.backend.domain.problem.service.DetectionCache;
import com.ieum.backend.domain.problem.service.ImageStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 삭제되지 않은 이미지 청소(주기, B안).
 * 다중 감지 후 학생이 선택하지 않고 DetectionCache TTL(10분)이 지난 업로드의 이미지는
 * 어떤 Problem도 참조하지 않아 삭제되지 않은 채 남는다 → 주기적으로 스토리지에서 삭제.
 * (createProblem 실패 즉시 정리(deleteAll)와 cancelProblem 즉시 삭제(A안)는 각 지점에서 처리)
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ProblemImageCleanupScheduler {

    private final DetectionCache detectionCache;
    private final ImageStorageService imageStorageService;

    @Scheduled(fixedDelay = 600_000) // 10분마다
    public void cleanupUnusedDetectionImages() {
        List<String> unused = detectionCache.sweepExpired();
        if (!unused.isEmpty()) {
            log.info("[ImageCleanup] 미선택 만료 업로드 미사용 이미지 {}건 삭제", unused.size());
            imageStorageService.deleteAll(unused); // best-effort (실패해도 예외 안 던짐)
        }
    }
}
