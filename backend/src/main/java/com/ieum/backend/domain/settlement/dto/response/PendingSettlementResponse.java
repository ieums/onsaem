package com.ieum.backend.domain.settlement.dto.response;

import com.ieum.backend.domain.settlement.entity.enums.PendingSettlementReason;

import java.time.LocalDateTime;

/**
 * 완료됐지만 아직 정산되지 않은 강의(정산 예정).
 * 강사 정산 화면에서 "왜 아직 정산 안 됐는지"를 보여주기 위한 표시용 DTO.
 */
public record PendingSettlementResponse(
        Long lessonId,
        Integer totalCoin,
        // 정산되면 받게 될 예상 강사 정산금(원).
        Integer expectedTutorAmount,
        // 표시용 과목(한글). 없을 수 있음.
        String subject,
        // 수업 날짜(종료 시각).
        LocalDateTime lessonDate,
        PendingSettlementReason reason
) {
}
