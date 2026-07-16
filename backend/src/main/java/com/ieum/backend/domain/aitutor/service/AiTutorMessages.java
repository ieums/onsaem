package com.ieum.backend.domain.aitutor.service;

/**
 * AI 튜터 도메인에서 사용자에게 보여지는 안내 메시지 모음.
 * 한 군데에서 관리해 톤·표현 일관성 유지.
 */
public final class AiTutorMessages {

    private AiTutorMessages() {
        // 상수 클래스 — 인스턴스화 금지
    }

    // ─── 4xx 에러 메시지 ───────────────────────────
    public static final String PROBLEM_NOT_FOUND          = "해당 문제를 찾을 수 없습니다.";
    public static final String SESSION_NOT_FOUND          = "세션을 찾을 수 없습니다.";
    public static final String SESSION_CLOSED             = "이미 종료된 세션입니다.";
    public static final String SESSION_PROBLEM_NOT_FOUND  = "세션에 연결된 문제를 찾을 수 없습니다.";

    // ─── Gemini 호출 실패 시 학생에게 응답하는 안내 ─
    public static final String GEMINI_FALLBACK            = "AI 튜터가 잠시 응답할 수 없어요. 잠시 후 다시 질문해주세요.";
}