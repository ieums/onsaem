package com.ieum.backend.domain.report.dto.request;

import com.ieum.backend.domain.report.entity.enums.ReportReason;
import com.ieum.backend.domain.report.entity.enums.ReportTargetType;
import com.ieum.backend.domain.report.entity.enums.ReporterType;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.Set;

/**
 * 신고 접수 요청.
 * reporterId는 인증 도입 전까지 본문으로 받음(이후 SecurityContext로 교체).
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class CreateReportRequest {

    @NotNull(message = "신고자 ID는 필수입니다")
    private Long reporterId;

    @NotNull(message = "신고자 유형은 필수입니다")
    private ReporterType reporterType;

    @NotNull(message = "신고 대상 유형은 필수입니다")
    private ReportTargetType targetType;

    @NotNull(message = "신고 대상 ID는 필수입니다")
    private Long targetId;

    private Long lessonId;   // 강의 종료 후 신고면 그 강의 (선택)

    @NotEmpty(message = "신고 사유는 1개 이상 선택해야 합니다")
    private Set<ReportReason> reasons;   // 여러 개 선택 가능

    @Size(max = 1000, message = "상세 설명은 1000자 이내로 입력해주세요")
    private String description;
}
