package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult.DetectedProblem;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * OCR로 여러 문제가 감지됐을 때, 학생이 하나를 고르기 전까지 결과를 잠깐 보관한다.
 * 선택 시 재OCR 없이 이 캐시에서 꺼내 저장한다.
 * 인메모리 + TTL (재시작/다중 인스턴스엔 안 남음 — MVP 허용).
 */
@Component
public class DetectionCache {

    private static final Duration TTL = Duration.ofMinutes(10);

    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    /** studentId: 이 결과를 업로드한 학생. 다른 학생이 detectionId로 선택하지 못하게 묶어 둔다. */
    public record Entry(Long studentId, List<DetectedProblem> detected, List<String> imageUrls, Instant expiresAt) {
        boolean isExpired(Instant now) {
            return expiresAt.isBefore(now);
        }
    }

    /** 감지 결과 저장 후 detectionId 반환 */
    public String put(Long studentId, List<DetectedProblem> detected, List<String> imageUrls) {
        String id = UUID.randomUUID().toString();
        store.put(id, new Entry(studentId, detected, imageUrls, Instant.now().plus(TTL)));
        return id;
    }

    /**
     * 항목을 꺼내면서 동시에 제거한다(원자적). 없거나 만료면 null.
     * 같은 detectionId로 요청이 동시에 두 번 와도 한 요청만 항목을 받는다.
     * 만료된 항목은 되돌려 두어 청소 스케줄러가 이미지를 삭제하게 한다.
     */
    public Entry take(String detectionId) {
        Entry e = store.remove(detectionId);
        if (e == null) {
            return null;
        }
        if (e.isExpired(Instant.now())) {
            store.putIfAbsent(detectionId, e);
            return null;
        }
        return e;
    }

    /** take()로 꺼낸 뒤 처리에 실패했을 때 다시 넣는다(원래 만료 시각 유지). */
    public void restore(String detectionId, Entry entry) {
        store.putIfAbsent(detectionId, entry);
    }

    /**
     * 만료된(= 학생이 선택 안 한 채 TTL 지난) 항목을 제거하고, 그 이미지 URL들을 반환한다.
     * 선택 완료 건은 이미 take()로 빠졌으므로, 여기 남은 만료 건의 이미지는 삭제되지 않은 채 남는다.
     * 청소 스케줄러가 이 URL들을 실제 스토리지에서 삭제한다.
     */
    public List<String> sweepExpired() {
        Instant now = Instant.now();
        List<String> unusedImageUrls = new ArrayList<>();
        store.entrySet().removeIf(en -> {
            if (en.getValue().isExpired(now)) {
                unusedImageUrls.addAll(en.getValue().imageUrls());
                return true;
            }
            return false;
        });
        return unusedImageUrls;
    }
}
