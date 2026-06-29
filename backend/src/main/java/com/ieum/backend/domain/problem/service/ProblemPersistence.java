package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

/**
 * 동시 등록 제한(PENDING 상한)을 "개수 확인 + INSERT"가 한 트랜잭션 안에서 원자적으로 일어나게 보장한다.
 * 별도 빈으로 분리해 프록시 기반 @Transactional이 동작하도록 한다(ProblemService는 NOT_SUPPORTED라 자가호출 불가).
 *
 * SERIALIZABLE로 둬서 동시에 같은 학생이 여러 업로드를 끝내도 상한을 넘겨 저장되지 않는다(저빈도라 경합 비용 무시 가능).
 */
@Service
@RequiredArgsConstructor
public class ProblemPersistence {

    private final ProblemRepository problemRepository;

    @Transactional(isolation = Isolation.SERIALIZABLE)
    public Problem saveUnderActiveLimit(Problem problem, Long studentId, int maxActive) {
        long active = problemRepository.countByStudentIdAndStatus(studentId, ProblemStatus.PENDING);
        if (active >= maxActive) {
            throw BusinessException.conflict(
                    "동시에 등록할 수 있는 질문은 최대 " + maxActive
                            + "개예요. 기존 질문을 마치거나 취소한 뒤 다시 시도해 주세요.");
        }
        return problemRepository.save(problem);
    }
}
