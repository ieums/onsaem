package com.ieum.backend.domain.problem.repository;

import com.ieum.backend.domain.problem.entity.Problem;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProblemRepository extends JpaRepository<Problem, Long> {

}
