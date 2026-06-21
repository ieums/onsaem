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

    private CreateReportRequest req(ReportReason reason) {
        return new CreateReportRequest(
                100L, ReporterType.STUDENT,
                ReportTargetType.TUTOR, 200L, 300L,
                reason, "부적절했습니다");
    }

    @Test
    @DisplayName("신고 접수 성공 — PENDING으로 저장")
    void create_success() {
        ReportResponse res = reportService.create(req(ReportReason.ABUSE));

        assertThat(res.status()).isEqualTo(ReportStatus.PENDING);
        assertThat(res.targetType()).isEqualTo(ReportTargetType.TUTOR);
        assertThat(reportRepository.count()).isEqualTo(1);
    }

    @Test
    @DisplayName("같은 신고자가 같은 대상·사유로 중복 신고하면 거부")
    void create_duplicate_rejected() {
        reportService.create(req(ReportReason.ABUSE));

        assertThatThrownBy(() -> reportService.create(req(ReportReason.ABUSE)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    @DisplayName("같은 대상이라도 사유가 다르면 신고 가능")
    void create_differentReason_allowed() {
        reportService.create(req(ReportReason.ABUSE));
        reportService.create(req(ReportReason.NO_SHOW));   // 다른 사유

        assertThat(reportRepository.count()).isEqualTo(2);
    }
}
