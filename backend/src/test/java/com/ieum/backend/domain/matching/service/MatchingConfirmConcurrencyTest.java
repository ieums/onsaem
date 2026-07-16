package com.ieum.backend.domain.matching.service;

import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.domain.auth.entity.Student;
import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.StudentRepository;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import com.ieum.backend.domain.matching.repository.MatchingApplicationRepository;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 매칭 확정(confirmMatch) 동시성 검증.
 *
 * 한 문제에 서로 다른 두 강사(A·B)의 신청이 모두 CONFIRMING(강사 확인 완료, 학생 확인 대기)인 상태에서,
 * 두 스레드가 "동시에" 학생 확인(confirmMatch)을 넣는다. 정상이면 한 문제에는 Lesson이 하나만 생겨야 한다.
 *
 * - 동시성 제어가 없으면: 둘 다 problem.status=PENDING을 읽고 각자 matchTutor()+createLesson() → Lesson 2개(실패).
 * - Problem 행 비관적 락(findByIdForUpdate) + 상태 가드가 있으면: 뒤늦은 확정은 MATCHED를 읽고 거부 → Lesson 1개(통과).
 */
@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("매칭 확정 동시성 — 한 문제에 Lesson 하나만")
class MatchingConfirmConcurrencyTest {

    @Autowired MatchingService matchingService;
    @Autowired ProblemRepository problemRepository;
    @Autowired MatchingApplicationRepository applicationRepository;
    @Autowired LessonRepository lessonRepository;
    @Autowired TutorRepository tutorRepository;
    @Autowired StudentRepository studentRepository;

    private Long problemId;
    private Long studentId;
    private Long tutorAId;
    private Long tutorBId;
    private String channelName;

    @BeforeEach
    void setUp() {
        applicationRepository.deleteAll();

        Student student = studentRepository.save(Student.builder()
                .name("학생").email("s-concurrency@test.com")
                .provider(AuthProvider.LOCAL).providerUserId("s-concurrency")
                .build());
        studentId = student.getId();
        Tutor tutorA = tutorRepository.save(Tutor.builder()
                .name("강사A").email("ta-concurrency@test.com")
                .provider(AuthProvider.LOCAL).providerUserId("ta-concurrency")
                .experienceYears(1).build());
        Tutor tutorB = tutorRepository.save(Tutor.builder()
                .name("강사B").email("tb-concurrency@test.com")
                .provider(AuthProvider.LOCAL).providerUserId("tb-concurrency")
                .experienceYears(1).build());

        tutorAId = tutorA.getId();
        tutorBId = tutorB.getId();

        Problem problem = problemRepository.save(Problem.builder()
                .studentId(student.getId())
                .build());
        problemId = problem.getId();
        channelName = "problem-" + problemId;

        // 두 강사 신청 모두 CONFIRMING + 강사 확인 완료 → 학생 확인만 들어오면 확정되는 상태로 만든다.
        applicationRepository.save(confirmingApplication(problemId, tutorAId));
        applicationRepository.save(confirmingApplication(problemId, tutorBId));
    }

    private MatchingApplication confirmingApplication(Long problemId, Long tutorId) {
        MatchingApplication app = MatchingApplication.builder()
                .problemId(problemId).tutorId(tutorId).build();
        app.confirm();       // PENDING → CONFIRMING
        app.tutorConfirm();  // 강사 확인 완료
        return app;
    }

    @AfterEach
    void tearDown() {
        applicationRepository.deleteAll();
        lessonRepository.findByChannelName(channelName)
                .ifPresent(l -> lessonRepository.deleteById(l.getId()));
        if (problemId != null) problemRepository.deleteById(problemId);
        if (tutorAId != null) tutorRepository.deleteById(tutorAId);
        if (tutorBId != null) tutorRepository.deleteById(tutorBId);
        if (studentId != null) studentRepository.deleteById(studentId);
    }

    @Test
    @DisplayName("두 강사의 학생 확인이 동시에 들어와도 Lesson은 한 건만 생성된다")
    void confirmMatch_concurrent_createsOnlyOneLesson() throws Exception {
        int threads = 2;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CyclicBarrier barrier = new CyclicBarrier(threads);
        List<Future<?>> futures = new ArrayList<>();
        List<Throwable> errors = new ArrayList<>();
        Long[] tutorIds = {tutorAId, tutorBId};

        for (int i = 0; i < threads; i++) {
            final Long tutorId = tutorIds[i];
            futures.add(pool.submit(() -> {
                try {
                    barrier.await();
                    matchingService.confirmMatch(problemId, tutorId, "student");
                } catch (Throwable t) {
                    synchronized (errors) {
                        errors.add(t);
                    }
                }
                return null;
            }));
        }

        for (Future<?> f : futures) {
            f.get();
        }
        pool.shutdown();

        long lessonCount = lessonRepository.findAll().stream()
                .filter(l -> channelName.equals(l.getChannelName()))
                .count();
        Problem problem = problemRepository.findById(problemId).orElseThrow();

        System.out.println("[매칭 확정 동시성] 생성된 Lesson 수 = " + lessonCount
                + ", 문제 상태 = " + problem.getStatus()
                + ", 거부된 요청 수 = " + errors.size());

        assertThat(lessonCount)
                .as("같은 문제에 동시 확정이 들어와도 Lesson은 한 건만 생성돼야 한다")
                .isEqualTo(1);
        assertThat(problem.getStatus())
                .as("확정 성공 시 문제는 MATCHED가 된다")
                .isEqualTo(ProblemStatus.MATCHED);
        assertThat(errors)
                .as("두 동시 확정 중 한쪽은 이미 매칭됨(conflict)으로 거부되어야 한다")
                .hasSize(1);
    }
}
