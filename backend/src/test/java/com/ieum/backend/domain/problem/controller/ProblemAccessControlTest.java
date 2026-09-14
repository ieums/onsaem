package com.ieum.backend.domain.problem.controller;

import com.ieum.backend.domain.auth.entity.Role;
import com.ieum.backend.domain.auth.jwt.JwtProvider;
import com.ieum.backend.domain.problem.dto.request.ClassificationUpdateRequest;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import com.ieum.backend.domain.problem.service.ImageStorageService;
import com.ieum.backend.domain.problem.service.ProblemService;
import com.ieum.backend.global.exception.BusinessException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 문제 API 인증·소유권 검증.
 * 예전에는 /api/v1/problems/** 가 permitAll이고 studentId를 요청값으로 받아,
 * 로그인 없이 남의 문제를 조회·수정·취소할 수 있었다.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"local", "test"})
@DisplayName("문제 API 인증·소유권")
class ProblemAccessControlTest {

    private static final long OWNER = 6100L;
    private static final long OTHER = 6200L;
    private static final long TUTOR = 6300L;

    @Autowired MockMvc mockMvc;
    @Autowired JwtProvider jwtProvider;
    @Autowired ProblemService problemService;
    @Autowired ProblemRepository problemRepository;
    @MockBean ImageStorageService imageStorageService;

    private Long problemId;

    @BeforeEach
    void setUp() {
        problemRepository.deleteAll();
        problemId = problemRepository.save(Problem.builder()
                .studentId(OWNER)
                .imageUrls(new ArrayList<>(List.of("/uploads/x.png", "/uploads/y.png")))
                .extractedText("다음 중 옳은 것은? ① 가 ② 나")
                .build()).getId();
    }

    @AfterEach
    void tearDown() {
        problemRepository.deleteAll();
    }

    private String bearer(long id, Role role) {
        return "Bearer " + jwtProvider.createAccessToken(id, role);
    }

    // ── 보안 설정 ─────────────────────────────────────────────
    @Test
    @DisplayName("토큰 없이 문제 API를 호출하면 401")
    void withoutToken_isUnauthorized() throws Exception {
        mockMvc.perform(get("/api/v1/problems/student")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/problems/" + problemId)).andExpect(status().isUnauthorized());
        mockMvc.perform(delete("/api/v1/problems/" + problemId)).andExpect(status().isUnauthorized());
        assertThat(problemRepository.findById(problemId).orElseThrow().getStatus()).isEqualTo(ProblemStatus.PENDING);
    }

    @Test
    @DisplayName("역할이 맞지 않으면 403 — 학생은 탐색 목록, 강사는 문제 취소 불가")
    void wrongRole_isForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/problems/searching").header("Authorization", bearer(OWNER, Role.STUDENT)))
                .andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/v1/problems/" + problemId).header("Authorization", bearer(TUTOR, Role.TUTOR)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("내 문제 목록은 요청값이 아니라 토큰의 학생 기준으로 조회된다")
    void studentList_usesTokenPrincipal() throws Exception {
        // 쿼리 파라미터로 남의 ID를 넣어도 무시되고, 토큰 주인의 목록만 나온다.
        mockMvc.perform(get("/api/v1/problems/student").param("studentId", String.valueOf(OWNER))
                        .header("Authorization", bearer(OTHER, Role.STUDENT)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));

        mockMvc.perform(get("/api/v1/problems/student").header("Authorization", bearer(OWNER, Role.STUDENT)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
    }

    @Test
    @DisplayName("다른 학생의 문제를 취소하려 하면 403이고 문제는 그대로 남는다")
    void cancelOthersProblem_isForbidden() throws Exception {
        mockMvc.perform(delete("/api/v1/problems/" + problemId).header("Authorization", bearer(OTHER, Role.STUDENT)))
                .andExpect(status().isForbidden());
        assertThat(problemRepository.findById(problemId).orElseThrow().getStatus()).isEqualTo(ProblemStatus.PENDING);
    }

    // ── 서비스 소유권 검사 ─────────────────────────────────────
    @Test
    @DisplayName("다른 학생은 조회·분류 수정·순서 변경·취소 모두 거부된다")
    void nonOwner_isRejectedOnEveryWrite() {
        assertThatThrownBy(() -> problemService.getProblem(problemId, OTHER, Role.STUDENT))
                .isInstanceOf(BusinessException.class).extracting("status").isEqualTo(HttpStatus.FORBIDDEN);
        assertThatThrownBy(() -> problemService.updateClassification(problemId, new ClassificationUpdateRequest(), OTHER))
                .isInstanceOf(BusinessException.class).extracting("status").isEqualTo(HttpStatus.FORBIDDEN);
        assertThatThrownBy(() -> problemService.reorderPages(problemId, List.of(1, 0), OTHER))
                .isInstanceOf(BusinessException.class).extracting("status").isEqualTo(HttpStatus.FORBIDDEN);
        assertThatThrownBy(() -> problemService.cancelProblem(problemId, OTHER))
                .isInstanceOf(BusinessException.class).extracting("status").isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    @DisplayName("본인과 강사는 단건 조회가 가능하다")
    void ownerAndTutor_canRead() {
        assertThat(problemService.getProblem(problemId, OWNER, Role.STUDENT)).isNotNull();
        assertThat(problemService.getProblem(problemId, TUTOR, Role.TUTOR)).isNotNull();
    }
}
