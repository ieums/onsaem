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

    public record Entry(List<DetectedProblem> detected, List<String> imageUrls, Instant expiresAt) {
    }

    /** 감지 결과 저장 후 detectionId 반환 */
    public String put(List<DetectedProblem> detected, List<String> imageUrls) {
        evictExpired();
        String id = UUID.randomUUID().toString();
        store.put(id, new Entry(detected, imageUrls, Instant.now().plus(TTL)));
        return id;
    }

    /** 만료됐거나 없으면 null */
    public Entry get(String detectionId) {
        Entry e = store.get(detectionId);
        if (e == null || e.expiresAt().isBefore(Instant.now())) {
            store.remove(detectionId);
            return null;
        }
        return e;
    }

    public void remove(String detectionId) {
        store.remove(detectionId);
    }

    private void evictExpired() {
        Instant now = Instant.now();
        store.entrySet().removeIf(en -> en.getValue().expiresAt().isBefore(now));
    }

    /**
     * 만료된(= 학생이 선택 안 한 채 TTL 지난) 항목을 제거하고, 그 이미지 URL들을 반환한다.
     * 선택 완료 건은 이미 remove()로 빠졌으므로, 여기 남은 만료 건의 이미지는 고아.
     * 청소 스케줄러가 이 URL들을 실제 스토리지에서 삭제한다.
     */
    public List<String> sweepExpired() {
        Instant now = Instant.now();
        List<String> orphanImageUrls = new ArrayList<>();
        store.entrySet().removeIf(en -> {
            if (en.getValue().expiresAt().isBefore(now)) {
                orphanImageUrls.addAll(en.getValue().imageUrls());
                return true;
            }
            return false;
        });
        return orphanImageUrls;
    }
}
