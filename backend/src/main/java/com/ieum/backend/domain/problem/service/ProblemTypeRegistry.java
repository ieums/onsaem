package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.entity.enums.Subject;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * 과목별 1차/2차 유형 매핑 레지스트리.
 * 프롬프트에 박지 않고 서버에서 관리 → 비용 절감 + 일관된 분류 보장.
 */
@Component
public class ProblemTypeRegistry {

    /**
     * 1차유형 (단원) — 과목별
     */
    private static final Map<Subject, List<String>> PRIMARY_TYPES = Map.of(
            Subject.MATH, List.of(
                    "공통수학1", "공통수학2",
                    "수학1", "수학2", "미적분", "확률과통계", "기하"
            ),
            Subject.KOREAN, List.of(
                    "공통국어",
                    "독서", "문학", "화법과작문", "언어와매체"
            ),
            Subject.ENGLISH, List.of(
                    "공통영어",
                    "독해", "듣기", "문법", "어휘"
            ),
            Subject.SOCIAL, List.of(
                    "통합사회",
                    "생활과윤리", "윤리와사상",
                    "한국지리", "세계지리",
                    "동아시아사", "세계사",
                    "경제", "정치와법", "사회문화"
            ),
            Subject.SCIENCE, List.of(
                    "통합과학",
                    "물리1", "물리2", "화학1", "화학2",
                    "생명과학1", "생명과학2", "지구과학1", "지구과학2"
            )
    );

    /**
     * 2차유형 (세부 단원) — 1차유형별
     */
    private static final Map<String, List<String>> SECONDARY_TYPES = Map.ofEntries(
            // ── 수학 ──
            Map.entry("공통수학1", List.of("다항식", "방정식과부등식", "도형의방정식")),
            Map.entry("공통수학2", List.of("집합과명제", "함수와그래프", "경우의수")),
            Map.entry("수학1", List.of("지수와로그", "삼각함수", "수열")),
            Map.entry("수학2", List.of("함수의극한", "미분", "적분")),
            Map.entry("미적분", List.of("수열의극한", "여러가지함수의미분", "여러가지적분")),
            Map.entry("확률과통계", List.of("경우의수", "확률", "통계")),
            Map.entry("기하", List.of("이차곡선", "평면벡터", "공간도형")),
            // ── 국어 ──
            Map.entry("공통국어", List.of("화법", "작문", "문법", "독서", "문학")),
            Map.entry("독서", List.of("인문", "사회", "과학기술", "예술", "논설문", "설명문")),
            Map.entry("문학", List.of("현대시", "고전시가", "현대소설", "고전소설", "극문학", "수필")),
            Map.entry("화법과작문", List.of("화법", "작문")),
            Map.entry("언어와매체", List.of("문법", "매체")),
            // ── 영어 ──
            Map.entry("공통영어", List.of("듣기", "어휘", "문법", "독해")),
            Map.entry("독해", List.of("주제찾기", "제목찾기", "요지파악", "함축의미", "빈칸추론",
                    "어법", "글의순서", "문장삽입", "문단요약", "장문독해")),
            Map.entry("듣기", List.of("듣기")),
            Map.entry("문법", List.of("어법")),
            Map.entry("어휘", List.of("어휘")),
            // ── 사회 ──
            Map.entry("통합사회", List.of("인간과사회", "정의와사회", "시장과경제", "환경과지속가능")),
            // ── 과학 ──
            Map.entry("통합과학", List.of("물질과규칙성", "시스템과상호작용", "변화와다양성", "환경과에너지"))
    );

    /**
     * primaryType 검증 — 과목에 속하지 않으면 null 반환
     */
    public String validatePrimaryType(Subject subject, String primaryType) {
        if (subject == null || primaryType == null) return null;
        List<String> validList = PRIMARY_TYPES.get(subject);
        if (validList == null) return null;
        return validList.contains(primaryType.trim()) ? primaryType.trim() : null;
    }

    /**
     * secondaryType 검증 — 1차유형에 속하지 않으면 null 반환
     */
    public String validateSecondaryType(String primaryType, String secondaryType) {
        if (primaryType == null || secondaryType == null) return null;
        List<String> validList = SECONDARY_TYPES.get(primaryType);
        if (validList == null) return null;
        return validList.contains(secondaryType.trim()) ? secondaryType.trim() : null;
    }

    /**
     * 과목별 1차유형 목록 (Flutter에서 수정 화면 만들 때 사용)
     */
    public List<String> getPrimaryTypes(Subject subject) {
        return PRIMARY_TYPES.getOrDefault(subject, List.of());
    }

    /**
     * 1차유형별 2차유형 목록 (Flutter 수정 화면용)
     */
    public List<String> getSecondaryTypes(String primaryType) {
        return SECONDARY_TYPES.getOrDefault(primaryType, List.of());
    }
    /**
     * 프롬프트에 박을 1차유형 목록을 문자열로 빌드
     */
    public String buildPrimaryTypePromptSection() {
        StringBuilder sb = new StringBuilder();
        PRIMARY_TYPES.forEach((subject, types) -> {
            sb.append(subject.name())
                    .append(" → ")
                    .append(String.join(", ", types))
                    .append("\n");
        });
        return sb.toString().trim();
    }

    /**
     * 프롬프트에 박을 2차유형 목록을 문자열로 빌드
     */
    public String buildSecondaryTypePromptSection() {
        StringBuilder sb = new StringBuilder();
        SECONDARY_TYPES.forEach((primary, types) -> {
            sb.append(primary)
                    .append(" → ")
                    .append(String.join(", ", types))
                    .append("\n");
        });
        return sb.toString().trim();
    }

}