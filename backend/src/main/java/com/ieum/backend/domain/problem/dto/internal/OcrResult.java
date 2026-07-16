package com.ieum.backend.domain.problem.dto.internal;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

/**
 * 1단계 OCR 결과 — 이미지에서 추출한 문제 텍스트들.
 *
 * <p>mode로 두 상황을 구분한다:
 * <ul>
 *   <li>{@link OcrMode#MULTI_PROBLEM} — 이미지(들)에 서로 다른 문제 여러 개. 기존 흐름(detectedTexts → 선택지).</li>
 *   <li>{@link OcrMode#SINGLE_MULTIPAGE} — 한 문제가 여러 장에 걸친 경우. pages(장별 텍스트) + suggestedOrder(올바른 읽기 순서).</li>
 * </ul>
 */
@Getter
@Setter
@NoArgsConstructor
public class OcrResult {

    /** OCR이 판단한 업로드 형태. */
    public enum OcrMode {
        /** 서로 다른 문제 여러 개(또는 단일 문제 단일 장). */
        MULTI_PROBLEM,
        /** 한 문제가 여러 장에 걸침 → 순서 재조합 대상. */
        SINGLE_MULTIPAGE
    }

    private OcrMode mode = OcrMode.MULTI_PROBLEM;

    /** MULTI_PROBLEM: 감지된 문제별 텍스트(기존). */
    private List<DetectedText> detectedTexts = new ArrayList<>();

    /** SINGLE_MULTIPAGE: 업로드한 각 이미지(장)의 텍스트. */
    private List<PageText> pages = new ArrayList<>();

    /** SINGLE_MULTIPAGE: 올바른 읽기 순서(이미지 인덱스 순열). 비면 업로드 순서 그대로. */
    private List<Integer> suggestedOrder = new ArrayList<>();

    @Getter
    @Setter
    @NoArgsConstructor
    public static class DetectedText {
        private String extractedText;   // 추출된 본문 (지문 + 문제 + 선택지)
        private String examCode;        // [25xxx-xxxx] 코드(수능특강/수능 완성의 경우에 있음)
        private Integer problemNumber;  // 문제 번호 (01, 02, 03...)
        /** 이 문제가 걸쳐 있는 업로드 이미지 인덱스들(0-based). 한 문제가 여러 장이면 [0,1]. 선택 시 이 장들만 저장. */
        private List<Integer> imageIndices = new ArrayList<>();
    }

    /** 한 문제 여러 장일 때, 업로드한 이미지 1장의 텍스트. */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class PageText {
        private int imageIndex;   // 업로드 순서상 이 페이지의 이미지 인덱스(0-based)
        private String pageText;  // 그 장에서 추출한 텍스트
    }
}
