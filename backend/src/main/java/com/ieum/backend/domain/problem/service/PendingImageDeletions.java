package com.ieum.backend.domain.problem.service;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * 유예 삭제 대기열.
 * 여러 문제 중 하나를 고를 때 제외되는 장은, 모델의 장 번호 판단이 틀렸을 수 있어 바로 지우지 않고
 * 유예 시간이 지난 뒤 ProblemImageCleanupScheduler가 삭제한다.
 *
 * 인메모리(재시작 시 대기열 소실) — 이 경우 이미지가 지워지지 않고 남는 쪽으로 실패하므로 원본 손실은 없다.
 */
@Component
public class PendingImageDeletions {

    static final Duration GRACE = Duration.ofHours(1);

    private record Pending(String url, Instant dueAt) {
    }

    // 모든 항목이 같은 유예 시간을 가지므로 넣은 순서 = 삭제 예정 순서.
    private final Queue<Pending> queue = new ConcurrentLinkedQueue<>();

    public void schedule(List<String> urls) {
        Instant dueAt = Instant.now().plus(GRACE);
        urls.forEach(url -> queue.add(new Pending(url, dueAt)));
    }

    /** 삭제 예정 시각이 지난 URL을 꺼낸다. */
    public List<String> drainDue(Instant now) {
        List<String> due = new ArrayList<>();
        Pending head;
        while ((head = queue.peek()) != null && !head.dueAt().isAfter(now)) {
            Pending polled = queue.poll();
            if (polled != null) {
                due.add(polled.url());
            }
        }
        return due;
    }

    /** 대기 중인 URL 목록(테스트·운영 확인용). */
    List<String> pendingUrls() {
        return queue.stream().map(Pending::url).toList();
    }
}
