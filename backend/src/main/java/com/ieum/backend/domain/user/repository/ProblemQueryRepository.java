package com.ieum.backend.domain.user.repository;

import com.ieum.backend.domain.user.service.ProblemContext;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class ProblemQueryRepository {

    private final JdbcTemplate jdbcTemplate;

    /**
     * problems 테이블은 OCR 담당자 소유 (읽기 전용)
     * problemId가 해당 학생의 문제일 때만 조회되어 소유권 검증을 겸함
     *
     */
    public Optional<ProblemContext> findContextByIdAndStudentId(Long problemId, Long studentId) {
        String sql = """
                SELECT subject, primary_type, secondary_type, grade,
                       difficulty, exam_type, extracted_text, summary, student_description
                FROM problems
                WHERE id = ? AND student_id = ?
                """;
        return jdbcTemplate.query(sql, this::mapRow, problemId, studentId)
                .stream()
                .findFirst();
    }

    private ProblemContext mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new ProblemContext(
                rs.getString("subject"),
                rs.getString("grade"),
                rs.getString("exam_type"),
                rs.getString("primary_type"),
                rs.getString("secondary_type"),
                rs.getString("difficulty"),
                rs.getString("extracted_text"),
                rs.getString("summary"),
                rs.getString("student_description")
        );
    }
}