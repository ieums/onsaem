package com.ieum.backend.domain.problem.dto.internal;

import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class AiAnalysisResult {

    private List<DetectedProblem> detectedProblems = new ArrayList<>();

    /** OCR이 판단한 업로드 형태(기본 MULTI_PROBLEM). SINGLE_MULTIPAGE면 아래 두 필드가 의미를 가진다. */
    private OcrResult.OcrMode mode = OcrResult.OcrMode.MULTI_PROBLEM;

    /**
     * SINGLE_MULTIPAGE일 때, 올바른 읽기 순서(이미지 인덱스 순열).
     * ProblemService가 이 순서대로 imageUrls를 재배치해 저장한다.
     */
    private List<Integer> imageOrder = new ArrayList<>();

    /**
     * SINGLE_MULTIPAGE일 때, imageOrder대로 정렬된 장별 텍스트.
     * 재정렬(드래그) 시 재OCR 없이 이 텍스트들을 새 순서로 재조합한다.
     */
    private List<String> pageTexts = new ArrayList<>();

    /**
     * 이미지에서 감지된 개별 문제 1건
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class DetectedProblem {
        private String extractedText;
        private String summary;
        /** OCR이 인식한 문제 번호(01·02…). 없으면 null. */
        private Integer problemNumber;
        /** 이 문제가 걸쳐 있는 업로드 이미지 인덱스들(0-based). 다중 문제 선택 시 이 장들만 저장. */
        private List<Integer> imageIndices = new ArrayList<>();
        private Subject subject;
        private String primaryType;
        private String secondaryType;
        private Difficulty difficulty;
        private Integer totalDifficultyScore;
        private ExamType examType;
        /** 분류 API가 실패해 기본값으로 채웠는지 여부(프론트가 분류 수정 화면으로 유도). */
        private boolean classificationFailed;
    }
}