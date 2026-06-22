package com.ieum.backend.domain.aitutor.service;

import org.springframework.stereotype.Component;
import com.ieum.backend.global.util.ClasspathLoader;

/**
 problems 데이터를 바탕으로 Gemini 에 보낼 시스템 프롬프트를 조립
 혼합형(힌트 우선) / 친근한 존댓말 / 적당히 상세 스타일을 기본으로 하고, 과목·난이도에 따라 미세조정 블록을 덧붙임
 */
@Component
public class GeminiPromptBuilder {

    /** [역할] + [답변 규칙] — 모든 프롬프트에 공통으로 들어가는 고정 텍스트 */
    private static final String HEADER = ClasspathLoader.loadAsString("prompts/ai-tutor-system.md");

    /**
problems 데이터로 Gemini 시스템 프롬프트를 생성
문제 원문(extractedText)이 비어 있을 떄
     */
    public String buildSystemInstruction(ProblemContext p) {
        StringBuilder sb = new StringBuilder();
        sb.append(HEADER).append('\n');
        sb.append(buildProblemSection(p)).append('\n');
        sb.append("[과목별 지침]\n").append(subjectBlock(p.subject())).append('\n');

        String difficulty = difficultyBlock(p.difficulty());
        if (!difficulty.isBlank()) {
            sb.append('\n').append("[난이도별 지침]\n").append(difficulty).append('\n');
        }
        return sb.toString();
    }

    /** [문제 정보] 섹션 — 값이 있는 줄만 추가(null/빈 값은 생략). */
    private String buildProblemSection(ProblemContext p) {
        if (p.extractedText() == null || p.extractedText().isBlank()) {
            throw new IllegalArgumentException("문제 원문(extractedText)이 없어 AI 튜터를 시작할 수 없습니다.");
        }
        StringBuilder sb = new StringBuilder("[문제 정보]\n");
        appendLine(sb, "과목", subjectLabel(p.subject()));
        appendLine(sb, "학년", p.grade());
        appendLine(sb, "시험 유형", p.examType());
        appendLine(sb, "문제 유형", typeLabel(p.primaryType(), p.secondaryType()));
        appendLine(sb, "난이도", p.difficulty());
        appendLine(sb, "문제 원문", p.extractedText());
        appendLine(sb, "한 줄 요약", p.summary());
        appendLine(sb, "학생이 남긴 설명", p.studentDescription());
        return sb.toString();
    }

    /** value 가 비어 있지 않을 때만 "- label: value" 한 줄을 추가 */
    private void appendLine(StringBuilder sb, String label, String value) {
        if (value != null && !value.isBlank()) {
            sb.append("- ").append(label).append(": ").append(value).append('\n');
        }
    }

    /** 과목 enum 값을 한글 라벨로. UNKNOWN/null 은 null 을 반환해 줄 자체를 생략 */
    private String subjectLabel(String subject) {
        if (subject == null) {
            return null;
        }
        return switch (subject.trim().toUpperCase()) {
            case "MATH" -> "수학";
            case "KOREAN" -> "국어";
            case "ENGLISH" -> "영어";
            case "SCIENCE" -> "과학";
            case "SOCIAL" -> "사회";
            default -> null;   // UNKNOWN 또는 알 수 없는 값 → 과목 줄 생략
        };
    }

    /** 1차·2차 유형을 "1차 > 2차" 형태로. 둘 다 없으면 null. */
    private String typeLabel(String primary, String secondary) {
        boolean hasPrimary = primary != null && !primary.isBlank();
        boolean hasSecondary = secondary != null && !secondary.isBlank();
        if (hasPrimary && hasSecondary) {
            return primary + " > " + secondary;
        }
        if (hasPrimary) {
            return primary;
        }
        if (hasSecondary) {
            return secondary;
        }
        return null;
    }

    /** 과목별 미세조정 블록. UNKNOWN/null 은 일반 튜터링 지침. */
    private String subjectBlock(String subject) {
        String s = (subject == null) ? "UNKNOWN" : subject.trim().toUpperCase();
        return switch (s) {
            case "MATH" -> "풀이를 단계로 나누고 각 단계의 개념·공식을 짚으세요. "
                    + "마지막 계산은 학생이 직접 하도록 비워두고, 수식은 한 줄씩 명확히 적으세요.";
            case "KOREAN" -> "답의 근거 문장을 학생이 직접 찾도록 '몇 번째 문단을 다시 보라'는 식으로 "
                    + "안내하세요. 어휘 의미는 문맥으로 추론하게 유도하세요.";
            case "ENGLISH" -> "어려운 문장은 주어·동사를 먼저 찾게 하고, 핵심 어휘는 문맥으로 추론하게 "
                    + "유도하세요. 문법 문제는 어떤 규칙이 쓰였는지 떠올리게 하세요.";
            case "SCIENCE" -> "풀이에 앞서 관련 개념·원리·법칙을 먼저 짚고, "
                    + "그것이 문제에 어떻게 적용되는지 연결하세요.";
            case "SOCIAL" -> "용어·개념을 학생이 자기 말로 설명하게 하고, "
                    + "자료(표·그래프·사례)에서 무엇을 읽어낼 수 있는지 묻는 질문으로 유도하세요.";
            default -> "특정 과목 지시 없이 일반 튜터링으로 진행하세요. "
                    + "풀이 방향이 모호하면 어떤 과목·단원인지 먼저 물어보세요.";
        };
    }

    /** 난이도별 미세조정 블록. MEDIUM/null 은 빈 문자열(섹션 생략). */
    private String difficultyBlock(String difficulty) {
        String d = (difficulty == null) ? "" : difficulty.trim().toUpperCase();
        return switch (d) {
            case "HARD" -> "풀이 단계를 더 잘게 쪼개고 힌트는 한 번에 하나씩만 주세요. "
                    + "학생이 막혀도 조급해하지 말고 격려하세요.";
            case "EASY" -> "유도를 짧게 하고 핵심만 짚어 학생이 빠르게 답에 도달하도록 도우세요.";
            default -> "";
        };
    }
}