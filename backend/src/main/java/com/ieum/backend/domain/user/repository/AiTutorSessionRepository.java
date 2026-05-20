package com.ieum.backend.domain.user.repository;

import com.ieum.backend.domain.user.entity.AiTutorSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AiTutorSessionRepository extends JpaRepository<AiTutorSession, Long> {

    // 세션 소유권 검증을 겸한 조회 (다른 학생의 세션 접근 차단)
    Optional<AiTutorSession> findByIdAndStudentId(Long id, Long studentId);
}