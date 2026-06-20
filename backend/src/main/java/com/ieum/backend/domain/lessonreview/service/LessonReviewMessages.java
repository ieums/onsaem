package com.ieum.backend.domain.lessonreview.service;

/**
 * 강의 복습 도메인에서 사용자에게 보여지는 안내 메시지 모음.
 * 한 군데에서 관리해 톤·표현 일관성 유지.
 */
public final class LessonReviewMessages {

    private LessonReviewMessages() {
        // 상수 클래스 — 인스턴스화 금지
    }

    // ─── 강의/세션 관련 4xx 에러 ────────────────────
    public static final String LESSON_NOT_FOUND               = "해당 강의를 찾을 수 없습니다.";
    public static final String LESSON_NOT_FOUND_FOR_SESSION   = "세션에 연결된 강의를 찾을 수 없습니다.";
    public static final String SESSION_NOT_FOUND              = "세션을 찾을 수 없습니다.";
    public static final String SESSION_CLOSED                 = "이미 종료된 세션입니다.";

    // ─── 트랜스크립트(전사) 준비 상태 안내 ─────────
    public static final String TRANSCRIPT_NOT_READY           = "복습 자료가 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요.";
    public static final String TRANSCRIPT_PROCESSING_TEMPLATE = "복습 자료가 아직 준비 중입니다 (상태: %s). 잠시 후 다시 시도해주세요.";

    // ─── PDF 상태별 응답 메시지 ──────────────────
    public static final String PDF_READY                      = "다운로드 준비 완료";
    public static final String PDF_PROCESSING                 = "PDF 학습 자료가 생성 중입니다. 잠시 후 다시 시도해 주세요.";
    public static final String PDF_FAILED                     = "PDF 생성에 실패했습니다. 잠시 후 다시 시도해 주세요.";
    public static final String PDF_NOT_READY                  = "PDF 학습 자료가 아직 준비되지 않았습니다.";

    // ─── Gemini 호출 실패 시 fallback (복습 챗봇용) ─
    public static final String GEMINI_FALLBACK                = "복습 챗봇이 잠시 응답할 수 없어요. 잠시 후 다시 질문해주세요.";

    // ─── 세션 자동 생성 제목 ────────────────────
    public static final String SESSION_TITLE_DEFAULT          = "강의 복습";
    public static final String SESSION_TITLE_SUFFIX           = " 수업 복습";  // {시각}+suffix 형태
}