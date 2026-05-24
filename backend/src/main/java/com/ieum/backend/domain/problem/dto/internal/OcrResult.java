package com.ieum.backend.domain.problem.dto.internal;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

/**
 * 1단계 OCR 결과 — 이미지에서 추출한 문제 텍스트들
 */
@Getter
@Setter
@NoArgsConstructor
public class OcrResult {

    private List<DetectedText> detectedTexts = new ArrayList<>();

    @Getter
    @Setter
    @NoArgsConstructor
    public static class DetectedText {
        private String extractedText;   // 추출된 본문 (지문 + 문제 + 선택지)
        private String examCode;        // [25xxx-xxxx] 코드(수능특강/수능 완성의 경우에 있음)
        private Integer problemNumber;  // 문제 번호 (01, 02, 03...)
    }
}