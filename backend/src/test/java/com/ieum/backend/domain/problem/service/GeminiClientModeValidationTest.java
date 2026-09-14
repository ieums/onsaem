package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;
import com.ieum.backend.domain.problem.dto.internal.ClassificationResult;
import com.ieum.backend.domain.problem.dto.internal.OcrResult;
import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import com.ieum.backend.global.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * OCR 모델의 모드 판단(SINGLE_MULTIPAGE)을 서버가 그대로 믿지 않는지 검증한다.
 * 외부 API 없이 GeminiOcrClient·GeminiClassifier를 Mock으로 대체한다.
 */
@DisplayName("OCR 모드 판단 검증")
class GeminiClientModeValidationTest {

    private final GeminiOcrClient ocrClient = mock(GeminiOcrClient.class);
    private final GeminiClassifier classifier = mock(GeminiClassifier.class);
    private final GeminiClient client = new GeminiClient(ocrClient, classifier);

    @BeforeEach
    void stubClassifier() {
        ClassificationResult c = new ClassificationResult();
        c.setSummary("요약");
        c.setSubject(Subject.KOREAN);
        c.setDifficulty(Difficulty.MEDIUM);
        c.setTotalDifficultyScore(50);
        c.setExamType(ExamType.UNKNOWN);
        when(classifier.classify(any(), any())).thenReturn(c);
    }

    private static List<MultipartFile> images(int count) {
        List<MultipartFile> list = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            list.add(new MockMultipartFile("images", "p" + i + ".jpg", "image/jpeg", new byte[]{1}));
        }
        return list;
    }

    private static OcrResult.PageText page(int imageIndex, String text) {
        OcrResult.PageText p = new OcrResult.PageText();
        p.setImageIndex(imageIndex);
        p.setPageText(text);
        return p;
    }

    private void ocrReturnsSingleMultipage(List<Integer> suggestedOrder, OcrResult.PageText... pages) {
        OcrResult r = new OcrResult();
        r.setMode(OcrResult.OcrMode.SINGLE_MULTIPAGE);
        r.setPages(new ArrayList<>(List.of(pages)));
        r.setSuggestedOrder(new ArrayList<>(suggestedOrder));
        when(ocrClient.extract(anyList())).thenReturn(r);
    }

    @Test
    @DisplayName("이미지가 1장인데 SINGLE_MULTIPAGE로 오면 MULTI_PROBLEM으로 되돌린다")
    void singleImage_isTreatedAsMultiProblem() {
        ocrReturnsSingleMultipage(List.of(0), page(0, "다음 글을 읽고 알맞은 것을 고르시오. ① 가 ② 나"));

        AiAnalysisResult result = client.analyze(images(1));

        assertThat(result.getMode()).isEqualTo(OcrResult.OcrMode.MULTI_PROBLEM);
        assertThat(result.getDetectedProblems()).hasSize(1);
        assertThat(result.getDetectedProblems().get(0).getImageIndices()).containsExactly(0);
        assertThat(result.getDetectedProblems().get(0).getExtractedText()).contains("고르시오");
    }

    @Test
    @DisplayName("장별 텍스트가 이미지 수보다 적으면(장 누락) 거부한다")
    void missingPage_isRejected() {
        ocrReturnsSingleMultipage(List.of(0, 2),
                page(0, "지문 앞부분입니다. 이어지는 내용이 있습니다."),
                page(2, "지문 뒷부분과 발문 ① 가 ② 나"));

        assertThatThrownBy(() -> client.analyze(images(3)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("다시 올려");
    }

    @Test
    @DisplayName("같은 장을 두 번 돌려주면 거부한다")
    void duplicatedPage_isRejected() {
        ocrReturnsSingleMultipage(List.of(0, 1),
                page(0, "지문 앞부분입니다. 이어지는 내용이 있습니다."),
                page(0, "지문 앞부분입니다. 이어지는 내용이 있습니다."));

        assertThatThrownBy(() -> client.analyze(images(2)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("다시 올려");
    }

    @Test
    @DisplayName("선택지가 두 장에서 각각 보이면 여러 문제가 묶인 것으로 보고 거부한다")
    void choicesOnSeveralPages_isRejected() {
        ocrReturnsSingleMultipage(List.of(0, 1),
                page(0, "1. 다음 중 옳은 것은? ① 가 ② 나 ③ 다"),
                page(1, "2. 다음 중 틀린 것은? ① 라 ② 마 ③ 바"));

        assertThatThrownBy(() -> client.analyze(images(2)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("나눠서");
    }

    @Test
    @DisplayName("EBS 문제 코드가 두 종류 이상이면 거부한다")
    void severalExamCodes_isRejected() {
        ocrReturnsSingleMultipage(List.of(0, 1),
                page(0, "[25002-0021] 지문 앞부분입니다."),
                page(1, "[25002-0022] 다음 물음에 답하시오."));

        assertThatThrownBy(() -> client.analyze(images(2)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("나눠서");
    }

    @Test
    @DisplayName("정상적인 한 문제 여러 장은 제안된 순서로 본문을 합치고 분류는 1회만 한다")
    void validMultipage_isOrderedAndCombined() {
        ocrReturnsSingleMultipage(List.of(1, 0),
                page(0, "지문 뒷부분과 발문입니다. ① 가 ② 나 ③ 다"),
                page(1, "지문 앞부분입니다."));

        AiAnalysisResult result = client.analyze(images(2));

        assertThat(result.getMode()).isEqualTo(OcrResult.OcrMode.SINGLE_MULTIPAGE);
        assertThat(result.getImageOrder()).containsExactly(1, 0);
        assertThat(result.getPageTexts()).containsExactly("지문 앞부분입니다.", "지문 뒷부분과 발문입니다. ① 가 ② 나 ③ 다");
        assertThat(result.getDetectedProblems()).hasSize(1);
        assertThat(result.getDetectedProblems().get(0).getExtractedText()).startsWith("지문 앞부분입니다.");
        org.mockito.Mockito.verify(classifier, org.mockito.Mockito.times(1)).classify(any(), any());
    }
}
