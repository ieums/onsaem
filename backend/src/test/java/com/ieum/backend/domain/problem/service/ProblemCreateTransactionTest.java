package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 문제 등록의 트랜잭션 경계 검증.
 *
 * createProblem이 NOT_SUPPORTED로 바뀐 뒤에도(이미지 저장·AI 호출은 트랜잭션 밖,
 * INSERT만 자체 트랜잭션) 전체 흐름이 정상 동작하는지 확인한다.
 * 특히 save 후 detached 엔티티의 LAZY imageUrls 접근에서 예외가 없어야 한다.
 *
 * 전제: test 프로파일이 gemini.api.key=none → OCR/분류가 Mock(문제 1개)으로 동작.
 */
@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("문제 등록 트랜잭션 경계")
class ProblemCreateTransactionTest {

    @Autowired ProblemService problemService;
    @Autowired ProblemRepository problemRepository;

    @AfterEach
    void tearDown() {
        problemRepository.deleteAll();
    }

    @Test
    @DisplayName("AI 호출을 트랜잭션 밖에서 해도 문제 등록·응답 매핑이 정상 동작한다")
    void createProblem_works_withTransactionOutsideAi() {
        MockMultipartFile image = new MockMultipartFile(
                "images", "problem.jpg", "image/jpeg", new byte[]{1, 2, 3, 4});

        ProblemCreateResponse response = problemService.createProblem(
                List.of(image),
                new ProblemCreateRequest(42L, null, "이 문제 풀이 부탁해요", null));

        // 응답 정상 (LAZY imageUrls 접근 포함)
        assertThat(response.getId()).isNotNull();
        assertThat(response.getStudentId()).isEqualTo(42L);
        assertThat(response.getImageUrls()).isNotEmpty();

        // 실제 DB에 저장됨 (자체 트랜잭션으로 커밋)
        assertThat(problemRepository.findById(response.getId())).isPresent();

        System.out.println("[문제 등록 트랜잭션] id=" + response.getId()
                + ", imageUrls=" + response.getImageUrls());
    }
}
