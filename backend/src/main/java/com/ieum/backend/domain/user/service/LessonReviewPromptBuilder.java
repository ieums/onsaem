package com.ieum.backend.domain.user.service;

import org.springframework.stereotype.Component;

import java.time.format.DateTimeFormatter;

/**
 * 복습 챗봇용 Gemini 시스템 프롬프트 조립.
 * 강의 전사 전체 + 답변 규칙을 시스템 프롬프트로 만듦.
 */
@Component
public class LessonReviewPromptBuilder {

    private static final String HEADER = """
            [역할]
            당신은 학생이 이미 들었던 과외 강의를 복습할 수 있게 돕는 친근한 AI 튜터예요.
            아래 강의 내용을 바탕으로 학생의 질문에 답해 주세요.
            """;

    private static final String FOOTER = """

            [답변 규칙]
            1. 학생의 질문은 위 강의 내용에 대한 것이므로, 강의 내용을 우선 근거로 답해 주세요.
            2. 강의에서 명확히 다룬 부분은 "강의에서 ~라고 설명드렸어요"처럼 어디서 나왔는지 짚어주세요.
            3. 강의에 없는 내용을 물으면 "강의에서는 다루지 않았지만"이라고 먼저 알리고 일반 설명을 해 주세요.
            4. 친근한 존댓말("~해요", "~해볼까요?")을 쓰세요.
            5. 답이 너무 길어지지 않게 핵심 위주로 깔끔하게 정리해 주세요.
            6. 학생이 이해 못 하는 부분은 다른 각도로 다시 설명해 주세요.
            """;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    public String buildSystemInstruction(LessonContext context) {
        if (context.transcript() == null || context.transcript().isBlank()) {
            throw new IllegalStateException("강의 전사 결과가 없어 복습을 시작할 수 없습니다.");
        }

        StringBuilder sb = new StringBuilder();
        sb.append(HEADER).append('\n');

        sb.append("[강의 정보]\n");
        if (context.startedAt() != null) {
            sb.append("- 시작 시각: ").append(context.startedAt().format(FMT)).append('\n');
        }
        if (context.endedAt() != null) {
            sb.append("- 종료 시각: ").append(context.endedAt().format(FMT)).append('\n');
        }
        if (context.summary() != null && !context.summary().isBlank()) {
            sb.append("- 한 줄 요약: ").append(context.summary()).append('\n');
        }
        sb.append('\n');

        sb.append("[강의 내용 (전사)]\n").append(context.transcript()).append('\n');

        sb.append(FOOTER);
        return sb.toString();
    }
}