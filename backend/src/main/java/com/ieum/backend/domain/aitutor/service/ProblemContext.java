package com.ieum.backend.domain.aitutor.service;

/**
 problems 테이블의 한 행을 담는 AI 튜터 도메인 전용 읽기 모델
 Problem 엔티티(OCR 담당자 소유)에 직접 의존하지 않기 위해 별도 record로 둠
 subject, difficulty 는 OCR 측 enum 과 결합되지 않도록 String 으로 받음
 값이 없을 수 있는 필드는 null 을 허용하며, 프롬프트 조립 시 해당 줄을 생략
 */
public record ProblemContext(
        String subject,             // 과목: KOREAN/MATH/ENGLISH/SOCIAL/SCIENCE/UNKNOWN
        String grade,               // 학년
        String examType,            // 시험 유형
        String primaryType,         // 1차 유형
        String secondaryType,       // 2차 유형
        String difficulty,          // 난이도: EASY/MEDIUM/HARD
        String extractedText,       // 문제 원문 (필수)
        String summary,             // 한 줄 요약
        String studentDescription   // 학생이 남긴 추가 설명
) {
}