package com.ieum.backend.domain.aitutor.controller;

import java.time.LocalDateTime;

public record SessionListItemResponse(
        Long sessionId,
        Long problemId,
        String title,
        String status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        // 이 세션에 쌓인 메시지 수. 0이면 입장만 하고 아직 질문 안 한 세션('이어서' 숨김 판단용).
        int messageCount,
        // 카톡식 미리보기: 마지막 메시지(보통 AI 답변)의 첫 줄. 없으면 null.
        String lastMessage
) {
}