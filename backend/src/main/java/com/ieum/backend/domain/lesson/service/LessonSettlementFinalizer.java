package com.ieum.backend.domain.lesson.service;

import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.payment.service.CoinService;
import com.ieum.backend.domain.settlement.dto.request.CalculateSettlementRequest;
import com.ieum.backend.domain.settlement.service.SettlementService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * 강의 1건의 "확정 차감 + 정산 생성"을 하나의 트랜잭션으로 묶는다(per-lesson 원자성).
 *
 * LessonService.finalizeDueSettlements가 강의마다 이 메서드를 호출한다. 별도 빈이라
 * {@code @Transactional}이 프록시로 적용되어 강의 한 건이 독립 트랜잭션으로 처리된다.
 * → 한 건이 실패해도 그 건만 롤백되고, 차감만 되고 정산이 안 되는 비원자 상태가 생기지 않는다.
 */
@Component
@RequiredArgsConstructor
public class LessonSettlementFinalizer {

    private final CoinService coinService;
    private final SettlementService settlementService;

    /** 한 강의: 코인 확정 차감 + 정산 생성을 같은 트랜잭션으로. 실패 시 이 건만 롤백. */
    @Transactional
    public void finalizeOne(Lesson lesson) {
        coinService.confirmDeduct(lesson.getStudentId(), lesson.getCoinCost(), lesson.getId());
        settlementService.calculate(new CalculateSettlementRequest(lesson.getId()));
    }
}
