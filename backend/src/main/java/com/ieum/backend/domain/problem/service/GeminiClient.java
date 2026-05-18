package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;

import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class GeminiClient {

    @Value("${gemini.api.key:none}")
    private String apiKey;

    private static final String ANALYSIS_PROMPT = """
        당신은 한국 고등학교 학습 콘텐츠 분류 전문가입니다.
        첨부된 문제 이미지를 분석하여 다음 JSON 형식으로만 답해주세요.
        반드시 아래 목록에서만 선택하세요. 목록에 없는 값은 절대 생성하지 마세요.
        
        {
          "extractedText": "이미지에서 추출한 문제 본문 (수식은 LaTeX)",
          "summary": "문제의 핵심을 한 줄로 요약",
          "subject": "KOREAN | MATH | ENGLISH | SOCIAL | SCIENCE",
          "primaryType": "1차유형",
          "secondaryType": "2차유형",
          "grade": "고1 | 고2 | 고3 | null",
          "difficulty": "EASY | MEDIUM | HARD",
          "totalDifficultyScore": 0~100,
          "examType": "SUNUNG | MOCK_EVALUATION | ACADEMIC_EVALUATION | EBS_SUNEUNG_TEUKGANG | EBS_SUNEUNG_WANSUNG | SCHOOL_INTERNAL | ACADEMY | null"
        }
        
        [1차유형 — 과목별]
        MATH → 수학1, 수학2, 미적분, 확률과통계, 기하
        KOREAN → 독서, 문학, 화법과작문, 언어와매체
        ENGLISH → 독해, 듣기, 문법, 어휘
        SOCIAL → 생활과윤리, 윤리와사상, 한국지리, 세계지리, 동아시아사, 세계사, 경제, 정치와법, 사회문화
        SCIENCE → 물리1, 물리2, 화학1, 화학2, 생명과학1, 생명과학2, 지구과학1, 지구과학2
        
        [2차유형 — 1차유형별]
        수학1 → 지수와로그, 삼각함수, 수열
        수학2 → 함수의극한, 미분, 적분
        미적분 → 수열의극한, 여러가지함수의미분, 여러가지적분
        확률과통계 → 경우의수, 확률, 통계
        기하 → 이차곡선, 평면벡터, 공간도형
        독서 → 인문, 사회, 과학기술, 예술, 논설문, 설명문
        문학 → 현대시, 고전시가, 현대소설, 고전소설, 극문학, 수필
        화법과작문 → 화법, 작문
        언어와매체 → 문법, 매체
        독해 → 주제찾기, 제목찾기, 요지파악, 함축의미, 빈칸추론, 어법, 글의순서, 문장삽입, 문단요약, 장문독해
        듣기 → 듣기
        문법 → 어법
        어휘 → 어휘
        
        [난이도 판단 기준]
        시험유형에 따라 가중치가 달라집니다.
        
        ■ 수능(SUNUNG), 평가원 모의고사(MOCK_EVALUATION), 학력평가(ACADEMIC_EVALUATION)인 경우:
          문항번호(30%) + 출제영역(20%) + 풀이단계수(25%) + 개념복합도(15%) + 계산량(10%)
          - 문항번호 기준: 1~10번=하, 11~20번=중, 21번·30번(킬러)=상
        
        ■ 그 외 시험(EBS, 학교내신, 학원, 기타, 시험유형 불명)인 경우:
          문항번호는 난이도와 무관하므로 제외.
          출제영역(25%) + 풀이단계수(35%) + 개념복합도(25%) + 계산량(15%)
        
        이 가중치를 적용하여 totalDifficultyScore(0~100)를 산출하세요.
        
        학년·시험유형은 본문에서 단서가 명확할 때만 답하고, 아니면 null.
        """;
    /**
     * 이미지 분석 (메인 메서드)
     * API 연결 전까지는 mock 데이터 리턴
     */
    public AiAnalysisResult analyze(MultipartFile image) {
        if ("none".equals(apiKey)) {
            return analyzeMock();
        }
        return analyzeReal(image);
    }

    /**
     * 실제 Gemini API 호출 (나중에 구현)
     */
    private AiAnalysisResult analyzeReal(MultipartFile image) {
        // TODO: Gemini API 연동
        // 1. 이미지를 Base64로 인코딩
        // 2. ANALYSIS_PROMPT + 이미지를 Gemini에 전송
        // 3. JSON 응답 파싱해서 AiAnalysisResult로 변환
        throw new UnsupportedOperationException("Gemini API 아직 미연동. .env에 GEMINI_API_KEY 설정 필요");
    }

    /**
     * 목 데이터 (API 연결 전 테스트용)
     */
    private AiAnalysisResult analyzeMock() {
        AiAnalysisResult result = new AiAnalysisResult();
        result.setExtractedText("sin(x² + 1)을 미분하시오. 풀이 과정에서 왜 2x를 곱해야 하는지 설명하시오.");
        result.setSummary("합성함수 미분 — 2x를 곱하는 이유");
        result.setSubject(Subject.MATH);
        result.setPrimaryType("미적분");
        result.setSecondaryType("여러가지함수의미분");
        result.setGrade("고2");
        result.setDifficulty(Difficulty.MEDIUM);
        result.setTotalDifficultyScore(52);
        result.setExamType(ExamType.MOCK_EVALUATION);
        return result;
    }
}