package com.ieum.backend.domain.problem.repository;

import com.ieum.backend.domain.problem.entity.Problem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface ProblemRepository extends JpaRepository<Problem, Long> {

    @Query("SELECT p FROM Problem p WHERE p.searching = true AND p.searchDeadline > :now")
    List<Problem> findAllSearching(@Param("now") LocalDateTime now);
}
