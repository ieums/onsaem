package com.ieum.backend.domain.lessonreview.repository;

import com.ieum.backend.domain.lessonreview.service.LessonInfo;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.List;

import java.util.Optional;

/**
 * lessons 테이블 읽기 전용.
 * lessons는 다른 팀원 소유 테이블이라 JPA 엔티티 만들지 않고 JdbcTemplate으로 직접 SELECT만.
 * (problems → ProblemQueryRepository와 같은 패턴)
 */
@Repository
@RequiredArgsConstructor
public class LessonQueryRepository {

    private final JdbcTemplate jdbcTemplate;

    /**
     * 특정 학생의 강의 한 건 조회 — 소유권 검증을 겸함.
     * 다른 학생의 강의 ID로 호출하면 빈 Optional 반환.
     */
    public Optional<LessonInfo> findByIdAndStudentId(Long lessonId, Long studentId) {
        String sql = """
                SELECT id, tutor_id, student_id, problem_id, channel_name, status,
                       recording_url, started_at, ended_at
                FROM lessons
                WHERE id = ? AND student_id = ?
                """;
        return jdbcTemplate.query(sql, this::mapRow, lessonId, studentId)
                .stream()
                .findFirst();
    }

    /**
     * 트랜스크립트가 아직 없는(또는 COMPLETED가 아닌) 종료된 강의 ID 목록.
     * Phase 2의 Scheduler가 호출 — 미처리 강의를 주기적으로 발견하기 위함.
     */
    public List<Long> findCompletedLessonIdsWithoutTranscript() {
        String sql = """
                SELECT l.id
                FROM lessons l
                WHERE l.status = 'COMPLETED'
                  AND l.recording_url IS NOT NULL
                  AND NOT EXISTS (
                      SELECT 1 FROM lesson_transcript t
                      WHERE t.lesson_id = l.id AND t.status = 'COMPLETED'
                  )
                  AND NOT EXISTS (
                      SELECT 1 FROM reports r
                      WHERE r.lesson_id = l.id AND r.status IN ('PENDING', 'REVIEWING')
                  )
                """;
        return jdbcTemplate.queryForList(sql, Long.class);
    }

    /**
     * 특정 학생의 '완료된' 강의 목록 (복습 목록용). 종료 시각 내림차순.
     * 전사 완료 여부와 무관하게 종료된 강의를 모두 내려주고, 준비 상태는 서비스에서 합친다.
     */
    public List<LessonInfo> findCompletedLessonsByStudentId(Long studentId) {
        String sql = """
                SELECT id, tutor_id, student_id, problem_id, channel_name, status,
                       recording_url, started_at, ended_at
                FROM lessons
                WHERE student_id = ? AND status = 'COMPLETED'
                ORDER BY ended_at DESC, id DESC
                """;
        return jdbcTemplate.query(sql, this::mapRow, studentId);
    }

    private LessonInfo mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new LessonInfo(
                rs.getLong("id"),
                rs.getLong("tutor_id"),
                rs.getLong("student_id"),
                rs.getObject("problem_id", Long.class),
                rs.getString("channel_name"),
                rs.getString("status"),
                rs.getString("recording_url"),
                toLocalDateTime(rs.getTimestamp("started_at")),
                toLocalDateTime(rs.getTimestamp("ended_at"))
        );
    }

    private static java.time.LocalDateTime toLocalDateTime(Timestamp ts) {
        return ts == null ? null : ts.toLocalDateTime();
    }

    /**
     * lesson ID만으로 단건 조회 — Scheduler가 사용 (학생 ID 없이 호출 필요).
     */
    public Optional<LessonInfo> findById(Long lessonId) {
        String sql = """
            SELECT id, tutor_id, student_id, problem_id, channel_name, status,
                   recording_url, started_at, ended_at
            FROM lessons
            WHERE id = ?
            """;
        return jdbcTemplate.query(sql, this::mapRow, lessonId)
                .stream()
                .findFirst();

    }
    /**
     * 강의에 매핑된 문제(problem)의 이미지 URL들을 페이지 순으로 반환.
     * lessons.problem_id가 NULL이거나 problem_images에 행이 없으면 빈 리스트.
     */
    public List<String> findProblemImageUrlsByLessonId(Long lessonId) {
        String sql = """
                SELECT pi.image_url
                FROM lessons l
                JOIN problem_images pi ON pi.problem_id = l.problem_id
                WHERE l.id = ?
                ORDER BY pi.page_order
                """;
        return jdbcTemplate.query(sql, (rs, n) -> rs.getString("image_url"), lessonId);
    }
}