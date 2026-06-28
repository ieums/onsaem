package com.ieum.backend.domain.matching.dto.response;

/**
 * 학생이 아직 수락하지 않은 매칭 요청(앱을 껐다 켰을 때 복구용).
 * 없으면 컨트롤러가 data=null 로 응답한다.
 */
public record PendingConfirmResponse(
        Long problemId,
        Long tutorId,
        String tutorName,
        String subject,        // 세션 복구(resumeMatching)에 필요
        String questionSummary // 세션 복구에 필요
) {}
