package com.ieum.backend.domain.matching.dto.response;

import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class ApplicantResponse {

    private Long applicationId;
    private Long tutorId;
    private LocalDateTime appliedAt;
    private ApplicationStatus status;

    public static ApplicantResponse from(MatchingApplication application) {
        return ApplicantResponse.builder()
                .applicationId(application.getId())
                .tutorId(application.getTutorId())
                .appliedAt(application.getAppliedAt())
                .status(application.getStatus())
                .build();
    }
}
