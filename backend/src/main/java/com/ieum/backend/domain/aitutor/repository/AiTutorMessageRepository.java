package com.ieum.backend.domain.aitutor.repository;

import com.ieum.backend.domain.aitutor.entity.AiTutorMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AiTutorMessageRepository extends JpaRepository<AiTutorMessage, Long> {

    // id 오름차순 = 생성 순서. createdAt은 동일 초 충돌 가능성이 있어 id로 정렬
    List<AiTutorMessage> findBySessionIdOrderByIdAsc(Long sessionId);

    // 목록 미리보기용 — 세션별 메시지 수, 마지막(가장 최근) 메시지 1건.
    int countBySessionId(Long sessionId);

    Optional<AiTutorMessage> findFirstBySessionIdOrderByIdDesc(Long sessionId);
}