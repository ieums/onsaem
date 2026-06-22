package com.ieum.backend.domain.report.service;

import com.ieum.backend.domain.report.dto.request.CreateReportRequest;
import com.ieum.backend.domain.report.dto.response.ReportResponse;
import com.ieum.backend.domain.report.entity.enums.ReportReason;
import com.ieum.backend.domain.report.entity.enums.ReportStatus;
import com.ieum.backend.domain.report.entity.enums.ReportTargetType;
import com.ieum.backend.domain.report.entity.enums.ReporterType;
import com.ieum.backend.domain.report.repository.ReportRepository;
import com.ieum.backend.global.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("신고 서비스")
class ReportServiceTest {

    @Autowired ReportService reportService;
    @Autowired ReportRepository reportRepository;

    @BeforeEach
    void setUp() {
        reportRepository.deleteAll();
    }

    private CreateReportRequest req(Set<ReportReason> reasons) {
        return new CreateReportRequest(
                100L, ReporterType.STUDENT,
                ReportTargetType.TUTOR, 200L, 300L,
                reasons, "부적절했습니다");
    }

    @Test
    @DisplayName("여러 사유를 한 건으로 접수 — PENDING으로 저장")
    void create_multipleReasons_success() {
        ReportResponse res = reportService.create(
                req(Set.of(ReportReason.NO_SHOW, ReportReason.ABUSE)));

        assertThat(res.status()).isEqualTo(ReportStatus.PENDING);
        assertThat(res.reasons()).containsExactlyInAnyOrder(ReportReason.NO_SHOW, ReportReason.ABUSE);
        assertThat(reportRepository.count()).isEqualTo(1);
    }

    @Test
    @DisplayName("같은 신고자가 같은 대상을 또 신고하면 거부 (대상당 1건)")
    void create_duplicateTarget_rejected() {
        reportService.create(req(Set.of(ReportReason.ABUSE)));

        // 사유가 달라도 같은 대상이면 차단
        assertThatThrownBy(() -> reportService.create(req(Set.of(ReportReason.NO_SHOW))))
                .isInstanceOf(BusinessException.class);
        assertThat(reportRepository.count()).isEqualTo(1);
    }

    @Test
    @DisplayName("대상이 다르면 신고 가능")
    void create_differentTarget_allowed() {
        reportService.create(req(Set.of(ReportReason.ABUSE)));   // 강사 200

        // 같은 신고자, 다른 대상(강사 201)
        reportService.create(new CreateReportRequest(
                100L, ReporterType.STUDENT,
                ReportTargetType.TUTOR, 201L, 300L,
                Set.of(ReportReason.ABUSE), null));

        assertThat(reportRepository.count()).isEqualTo(2);
    }
}
