package com.ieum.backend.domain.settlement.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 정산 생성 요청.
 *
 * lessonId만 받는다 — 정산받을 강사와 금액은 요청값을 신뢰하지 않고
 * 서버가 강의(Lesson)에서 직접 구한다(SettlementService.calculate).
 * 예전에는 tutorId·totalCoin도 필수로 받았지만 실제로는 무시되고 있어,
 * "이 값으로 정산된다"는 오해를 줄 수 있어 제거했다.
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class CalculateSettlementRequest {

    @NotNull(message = "강의 ID는 필수입니다")
    private Long lessonId;
}