package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;
import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult.DetectedProblem;
import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemSelectRequest;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import com.ieum.backend.global.exception.BusinessException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 여러 문제 감지 → 선택 경로 검증.
 * 이미지 저장소와 AI 분석은 Mock으로 대체한다(파일·외부 API 없이 분기만 재현).
 */
@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("여러 문제 선택 경로")
class ProblemSelectTest {

    private static final long STUDENT = 5100L;
    private static final long OTHER_STUDENT = 5200L;

    @Autowired ProblemService problemService;
    @Autowired ProblemPersistence problemPersistence;
    @Autowired ProblemRepository problemRepository;
    @Autowired DetectionCache detectionCache;
    @Autowired PendingImageDeletions pendingImageDeletions;
    @Autowired PlatformTransactionManager transactionManager;
    @MockBean ImageStorageService imageStorageService;
    @MockBean GeminiClient geminiClient;

    @BeforeEach
    @AfterEach
    void clean() {
        problemRepository.deleteAll();
    }

    private static DetectedProblem detected(String text, Integer... imageIndices) {
        DetectedProblem p = new DetectedProblem();
        p.setExtractedText(text);
        p.setSummary("요약");
        p.setSubject(Subject.MATH);
        p.setImageIndices(new ArrayList<>(List.of(imageIndices)));
        return p;
    }

    private static List<DetectedProblem> twoProblems() {
        return new ArrayList<>(List.of(
                detected("1. 다음 중 옳은 것은? ① 가 ② 나 ③ 다", 0),
                detected("2. 다음 중 틀린 것은? ① 라 ② 마 ③ 바", 1)));
    }

    private static ProblemSelectRequest select(String detectionId, int index) {
        return new ProblemSelectRequest(detectionId, index, null, null);
    }

    private long pendingCount(long studentId) {
        return problemRepository.countByStudentIdAndStatus(studentId, ProblemStatus.PENDING);
    }

    // ── 4번: 레거시 경로 제거 후에도 여러 문제 감지는 선택 대기로 간다 ──────────
    @Test
    @DisplayName("여러 문제가 감지되면 저장하지 않고, 업로드한 학생에게 묶인 선택 대기 응답을 준다")
    void multipleDetected_returnsSelectionBoundToStudent() {
        AiAnalysisResult analysis = new AiAnalysisResult();
        analysis.setDetectedProblems(twoProblems());
        when(geminiClient.analyze(anyList())).thenReturn(analysis);
        when(imageStorageService.storeAll(anyList())).thenReturn(List.of("/uploads/a.png", "/uploads/b.png"));

        ProblemCreateResponse res = problemService.createProblem(
                List.of(new MockMultipartFile("images", new byte[]{1}), new MockMultipartFile("images", new byte[]{2})),
                new ProblemCreateRequest(null, null), STUDENT);

        assertThat(res.getNeedsSelection()).isTrue();
        assertThat(res.getDetectionId()).isNotBlank();
        assertThat(pendingCount(STUDENT)).isZero();

        // 다른 학생은 이 detectionId로 선택할 수 없고, 거부돼도 원래 학생의 선택 기회는 남는다.
        assertThatThrownBy(() -> problemService.selectDetectedProblem(select(res.getDetectionId(), 0), OTHER_STUDENT))
                .isInstanceOf(BusinessException.class)
                .extracting("status").isEqualTo(HttpStatus.FORBIDDEN);

        ProblemCreateResponse registered = problemService.selectDetectedProblem(select(res.getDetectionId(), 0), STUDENT);
        assertThat(registered.getId()).isNotNull();
        assertThat(registered.getStudentId()).isEqualTo(STUDENT);
    }

    // ── 3번: 같은 선택 동시 요청 ─────────────────────────────────────
    @Test
    @DisplayName("같은 detectionId로 동시에 두 번 선택해도 문제는 한 건만 생성된다")
    void concurrentSameSelection_createsOnlyOne() throws Exception {
        String detectionId = detectionCache.put(STUDENT, twoProblems(), List.of("/uploads/a.png", "/uploads/b.png"));

        int threads = 2;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CyclicBarrier barrier = new CyclicBarrier(threads);
        List<Future<?>> futures = new ArrayList<>();
        List<Throwable> errors = new ArrayList<>();
        for (int i = 0; i < threads; i++) {
            futures.add(pool.submit(() -> {
                try {
                    barrier.await();
                    problemService.selectDetectedProblem(select(detectionId, 0), STUDENT);
                } catch (Throwable t) {
                    synchronized (errors) {
                        errors.add(t);
                    }
                }
                return null;
            }));
        }
        for (Future<?> f : futures) f.get();
        pool.shutdown();

        System.out.println("[선택 동시성] 생성된 문제 수 = " + pendingCount(STUDENT) + ", 거부된 요청 수 = " + errors.size());
        assertThat(pendingCount(STUDENT)).isEqualTo(1);
        assertThat(errors).hasSize(1);
        assertThat(errors.get(0)).isInstanceOf(BusinessException.class);
    }

    // ── 2번: 선택 경로의 트랜잭션 경계 ────────────────────────────────
    @Test
    @DisplayName("선택 등록은 호출부 트랜잭션에 합류하지 않고 자기 트랜잭션(SERIALIZABLE)으로 커밋된다")
    void selection_commitsInItsOwnTransaction() {
        String detectionId = detectionCache.put(STUDENT, twoProblems(), List.of("/uploads/a.png", "/uploads/b.png"));

        // 바깥 트랜잭션을 롤백시켜도, 선택 등록이 그 트랜잭션에 합류하지 않았다면 문제는 남아 있어야 한다.
        // (합류했다면 SERIALIZABLE도 무시된 것 — 격리 수준은 새 트랜잭션에만 적용되기 때문)
        new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
            problemService.selectDetectedProblem(select(detectionId, 0), STUDENT);
            status.setRollbackOnly();
        });

        assertThat(pendingCount(STUDENT)).isEqualTo(1);
    }

    @Test
    @DisplayName("상한 확인 + 저장은 호출부가 트랜잭션 안이어도 항상 새 트랜잭션으로 실행된다")
    void persistence_alwaysStartsNewTransaction() {
        new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
            problemPersistence.saveUnderActiveLimit(
                    Problem.builder().studentId(STUDENT).extractedText("다음 중 옳은 것은? ① 가").build(),
                    STUDENT, 3);
            status.setRollbackOnly();
        });

        assertThat(pendingCount(STUDENT)).isEqualTo(1);
    }

    // ── 7번: 선택 시 이미지 보존 규칙 ────────────────────────────────
    @Test
    @DisplayName("어느 문제에도 배정되지 않은 장은 남기고, 다른 문제의 장은 즉시 지우지 않고 유예 삭제로 넘긴다")
    void unclaimedPageIsKept_andOthersAreDeferred() {
        List<String> urls = List.of("/uploads/p0.png", "/uploads/p1.png", "/uploads/p2.png");
        // 문제 A는 0번 장, 문제 B는 1번 장. 2번 장은 모델이 어디에도 배정하지 않음.
        String detectionId = detectionCache.put(STUDENT, twoProblems(), urls);

        ProblemCreateResponse res = problemService.selectDetectedProblem(select(detectionId, 0), STUDENT);

        assertThat(res.getImageUrls()).containsExactly("/uploads/p0.png", "/uploads/p2.png");
        verify(imageStorageService, never()).delete(anyString());
        verify(imageStorageService, never()).deleteAll(anyList());
        assertThat(pendingImageDeletions.pendingUrls()).contains("/uploads/p1.png");
    }

    @Test
    @DisplayName("다른 문제의 장 번호가 범위를 벗어나면 신뢰할 수 없으므로 전부 남긴다")
    void untrustedIndices_keepAllPages() {
        List<String> urls = List.of("/uploads/q0.png", "/uploads/q1.png");
        List<DetectedProblem> problems = new ArrayList<>(List.of(
                detected("1. 다음 중 옳은 것은? ① 가 ② 나 ③ 다", 0),
                detected("2. 다음 중 틀린 것은? ① 라 ② 마 ③ 바", 5)));
        String detectionId = detectionCache.put(STUDENT, problems, urls);

        ProblemCreateResponse res = problemService.selectDetectedProblem(select(detectionId, 0), STUDENT);

        assertThat(res.getImageUrls()).containsExactly("/uploads/q0.png", "/uploads/q1.png");
        assertThat(pendingImageDeletions.pendingUrls()).doesNotContain("/uploads/q0.png", "/uploads/q1.png");
    }

    @Test
    @DisplayName("저장이 실패하면(본문이 너무 짧음) 선택 대기 항목을 되돌려 다른 문제를 다시 고를 수 있다")
    void failedSelection_restoresEntry() {
        List<DetectedProblem> problems = new ArrayList<>(List.of(
                detected("짧음", 0),
                detected("2. 다음 중 틀린 것은? ① 라 ② 마 ③ 바", 1)));
        String detectionId = detectionCache.put(STUDENT, problems, List.of("/uploads/r0.png", "/uploads/r1.png"));

        assertThatThrownBy(() -> problemService.selectDetectedProblem(select(detectionId, 0), STUDENT))
                .isInstanceOf(BusinessException.class);

        ProblemCreateResponse res = problemService.selectDetectedProblem(select(detectionId, 1), STUDENT);
        assertThat(res.getId()).isNotNull();
    }
}
