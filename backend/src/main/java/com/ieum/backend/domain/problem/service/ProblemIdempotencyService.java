package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;

/**
 * 문제 등록(createProblem) 중복 차단.
 * 같은 Idempotency-Key로 짧은 시간 안에 다시 들어오면, 처음 만든 결과를 그대로 돌려준다(2번 등록 방지).
 * - 키별 락으로 동시 요청을 직렬화 → 진행 중 재시도가 두 번 처리되지 않음.
 * - 실패(예외)는 캐싱하지 않음 → 진짜 실패는 사용자가 다시 시도 가능.
 * - 인메모리 + TTL (재시작/다중 인스턴스엔 안 남음 — MVP 허용, DetectionCache와 동일 정책).
 */
@Slf4j
@Service
public class ProblemIdempotencyService {

    private static final Duration TTL = Duration.ofMinutes(10);

    private record Entry(ProblemCreateResponse response, Instant expiresAt) {}

    private final Map<String, Entry> store = new ConcurrentHashMap<>();
    private final Map<String, Object> locks = new ConcurrentHashMap<>();

    public ProblemCreateResponse execute(String key, Supplier<ProblemCreateResponse> action) {
        // 키가 없으면 멱등 처리 없이 그대로 실행.
        if (key == null || key.isBlank()) {
            return action.get();
        }
        Object lock = locks.computeIfAbsent(key, k -> new Object());
        synchronized (lock) {
            evictExpired();
            Entry cached = store.get(key);
            if (cached != null && cached.expiresAt().isAfter(Instant.now())) {
                log.info("중복 업로드 감지(Idempotency-Key={}) — 기존 결과 반환", key);
                return cached.response();
            }
            ProblemCreateResponse resp = action.get(); // 실패 시 예외 → 캐싱 안 함
            // 선택 대기(needsSelection) 응답은 일회용 detectionId를 담는다 —
            // 캐시해 두면 재업로드 시 이미 소비된 detectionId를 되돌려줘 /select에서 "만료" 에러가 난다.
            // 따라서 최종 결과(등록 완료/분류 실패)만 캐시하고, 선택 대기 응답은 매번 새로 OCR하게 둔다.
            if (!Boolean.TRUE.equals(resp.getNeedsSelection())) {
                store.put(key, new Entry(resp, Instant.now().plus(TTL)));
            }
            return resp;
        }
    }

    private void evictExpired() {
        Instant now = Instant.now();
        store.entrySet().removeIf(en -> en.getValue().expiresAt().isBefore(now));
    }
}
