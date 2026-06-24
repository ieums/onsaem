package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult.DetectedProblem;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
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
}
