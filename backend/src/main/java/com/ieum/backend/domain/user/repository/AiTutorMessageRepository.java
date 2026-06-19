package com.ieum.backend.domain.user.repository;

import com.ieum.backend.domain.user.entity.AiTutorMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AiTutorMessageRepository extends JpaRepository<AiTutorMessage, Long> {

    // id 오름차순 = 생성 순서. createdAt은 동일 초 충돌 가능성이 있어 id로 정렬
    List<AiTutorMessage> findBySessionIdOrderByIdAsc(Long sessionId);
}