package com.ieum.backend.domain.problem.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ieum.backend.domain.problem.dto.internal.OcrResult;
import com.ieum.backend.domain.problem.dto.internal.OcrResult.DetectedText;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 지문 묶음 연결 검증 — 모델 응답 JSON을 넣어 파싱·후처리 결과를 확인한다(외부 API 호출 없음).
 *
 * 실제 사례: 국어 [14~17] 지문 2장을 올리자 모델이 지문을 14번에만 넣고 15~17번은 문제 번호부터 시작했다.
 * 16번을 고르면 지문 텍스트와 지문 장(1장)이 함께 저장되지 않았다.
 */
@DisplayName("OCR 지문 묶음 연결")
class GeminiOcrPassageLinkTest {

    private static final String PASSAGE =
            "[14~17] 다음 글을 읽고 물음에 답하시오.\n\n"
                    + "주차하거나 좁은 길을 지날 때 운전자를 돕는 장치들이 있다. 이 중 차량 전후좌우에 장착된 카메라로 촬영한 영상을 이용하여 "
                    + "차량 주위 360°의 상황을 위에서 내려다본 것 같은 영상을 만들어 운전자에게 제공하는 장치가 있다.\n"
                    + "먼저 차량 주위 바닥에 바둑판 모양의 격자판을 펴 놓고 카메라로 촬영한다.";

    private final GeminiOcrClient client = new GeminiOcrClient();
    private final ObjectMapper mapper = new ObjectMapper();

    private static Map<String, Object> problem(int number, String text, List<Integer> pages) {
        Map<String, Object> p = new LinkedHashMap<>();
        p.put("extractedText", text);
        p.put("examCode", null);
        p.put("problemNumber", number);
        p.put("imageIndices", pages);
        return p;
    }

    /** 모델 응답(detectedTexts)을 Gemini 응답 봉투에 담아 parseResponse에 넣는다. */
    private List<DetectedText> parse(List<Map<String, Object>> detectedTexts) throws Exception {
        String modelJson = mapper.writeValueAsString(Map.of("mode", "MULTI_PROBLEM", "detectedTexts", detectedTexts));
        String envelope = mapper.writeValueAsString(Map.of("candidates", List.of(
                Map.of("content", Map.of("parts", List.of(Map.of("text", modelJson)))))));
        OcrResult result = client.parseResponse(envelope);
        return result.getDetectedTexts();
    }

    private static DetectedText byNumber(List<DetectedText> list, int number) {
        return list.stream().filter(t -> Integer.valueOf(number).equals(t.getProblemNumber())).findFirst().orElseThrow();
    }

    @Test
    @DisplayName("실제 사례: 지문이 14번에만 있어도 15~17번에 지문 텍스트와 지문 장이 붙는다")
    void passageOnlyInFirstProblem_isLinkedToWholeGroup() throws Exception {
        List<DetectedText> result = parse(List.of(
                problem(14, PASSAGE + "\n\n14. 윗글의 내용과 일치하는 것은?\n① 가\n② 나", List.of(0)),
                problem(15, "15. ㉠~㉢을 이해한 내용으로 가장 적절한 것은?\n① 가\n② 나", List.of(1)),
                problem(16, "16. 윗글을 바탕으로 <보기>를 탐구한 내용으로 가장 적절한 것은? [3점]\n<보 기>\n그림은…\n① 가", List.of(1)),
                problem(17, "17. 문맥상 ⓐ의 의미와 가장 가까운 것은?\n① 가\n② 나", List.of(1))));

        DetectedText p16 = byNumber(result, 16);
        assertThat(p16.getImageIndices()).containsExactly(0, 1);
        assertThat(p16.getExtractedText()).startsWith("[14~17] 다음 글을 읽고");
        assertThat(p16.getExtractedText()).contains("16. 윗글을 바탕으로 <보기>를 탐구한");

        assertThat(byNumber(result, 15).getImageIndices()).containsExactly(0, 1);
        assertThat(byNumber(result, 17).getImageIndices()).containsExactly(0, 1);
        assertThat(byNumber(result, 17).getExtractedText()).startsWith("[14~17]");

        // 지문을 원래 가진 14번은 그대로(지문 중복 없음)
        DetectedText p14 = byNumber(result, 14);
        assertThat(p14.getImageIndices()).containsExactly(0);
        assertThat(p14.getExtractedText().split("\\[14~17]", -1)).hasSize(2);
    }

    @Test
    @DisplayName("모델이 지문을 이미 반복해 넣었다면 다시 붙이지 않는다")
    void passageAlreadyRepeated_isNotDuplicated() throws Exception {
        List<DetectedText> result = parse(List.of(
                problem(14, PASSAGE + "\n\n14. 윗글의 내용과 일치하는 것은?\n① 가", List.of(0)),
                problem(15, PASSAGE + "\n\n15. ㉠~㉢을 이해한 내용으로 가장 적절한 것은?\n① 가", List.of(0, 1))));

        DetectedText p15 = byNumber(result, 15);
        assertThat(p15.getExtractedText().split("\\[14~17]", -1)).hasSize(2);
        assertThat(p15.getImageIndices()).containsExactly(0, 1);
    }

    @Test
    @DisplayName("[01~03]처럼 0이 붙은 범위와 01. 문제 번호도 연결된다")
    void zeroPaddedRange_isLinked() throws Exception {
        String passage = "[01~03] 다음 글을 읽고 물음에 답하시오.\n\n지문 내용이 이어진다. 두 번째 문장이다.";
        List<DetectedText> result = parse(List.of(
                problem(1, passage + "\n01. 윗글에 대한 설명으로 적절한 것은?\n① 가", List.of(0)),
                problem(3, "03. 윗글을 읽고 추론한 내용으로 적절한 것은?\n① 가", List.of(1))));

        DetectedText p3 = byNumber(result, 3);
        assertThat(p3.getImageIndices()).containsExactly(0, 1);
        assertThat(p3.getExtractedText()).startsWith("[01~03]");
    }

    @Test
    @DisplayName("범위 표기가 없는 독립 문제들은 건드리지 않는다")
    void independentProblems_areUntouched() throws Exception {
        List<DetectedText> result = parse(List.of(
                problem(19, "19. 로그함수 y=log x의 그래프와 접선을 이용해 넓이를 구하시오.\n① 1\n② 2", List.of(0)),
                problem(20, "20. 수열의 합을 구하시오.\n① 3\n② 4", List.of(1))));

        assertThat(byNumber(result, 19).getImageIndices()).containsExactly(0);
        assertThat(byNumber(result, 20).getImageIndices()).containsExactly(1);
        assertThat(byNumber(result, 20).getExtractedText()).startsWith("20.");
    }

    @Test
    @DisplayName("묶음 범위를 벗어난 번호의 문제에는 지문을 붙이지 않는다")
    void problemOutsideRange_isNotLinked() throws Exception {
        List<DetectedText> result = parse(List.of(
                problem(14, PASSAGE + "\n\n14. 윗글의 내용과 일치하는 것은?\n① 가", List.of(0)),
                problem(18, "18. 다음 중 맞춤법이 옳은 것은?\n① 가", List.of(1))));

        assertThat(byNumber(result, 18).getImageIndices()).containsExactly(1);
        assertThat(byNumber(result, 18).getExtractedText()).startsWith("18.");
    }
}
