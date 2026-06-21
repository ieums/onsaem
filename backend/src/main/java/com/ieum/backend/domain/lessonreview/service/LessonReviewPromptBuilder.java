package com.ieum.backend.domain.lessonreview.service;

import com.ieum.backend.global.util.ClasspathLoader;
import org.springframework.stereotype.Component;

import java.time.format.DateTimeFormatter;

/**
 * 복습 챗봇용 Gemini 시스템 프롬프트 조립.
 * 외부 템플릿(prompts/lesson-review-system.md) 의 placeholder 를
 * 강의 정보·전사 내용으로 채워 반환.
 */
@Component
public class LessonReviewPromptBuilder {

    private static final String TEMPLATE = ClasspathLoader.loadAsString("prompts/lesson-review-system.md");
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    public String buildSystemInstruction(LessonContext context) {
        if (context.transcript() == null || context.transcript().isBlank()) {
            throw new IllegalStateException("강의 전사 결과가 없어 복습을 시작할 수 없습니다.");
        }

        // {{lessonInfo}} 섹션 — 값 없는 항목은 줄 생략
        StringBuilder lessonInfo = new StringBuilder();
        if (context.startedAt() != null) {
            lessonInfo.append("- 시작 시각: ").append(context.startedAt().format(FMT)).append('\n');
        }
        if (context.endedAt() != null) {
            lessonInfo.append("- 종료 시각: ").append(context.endedAt().format(FMT)).append('\n');
        }
        if (context.summary() != null && !context.summary().isBlank()) {
            lessonInfo.append("- 한 줄 요약: ").append(context.summary()).append('\n');
        }

        return TEMPLATE
                .replace("{{lessonInfo}}", lessonInfo.toString().trim())
                .replace("{{transcript}}", context.transcript());
    }
}