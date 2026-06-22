package com.ieum.backend.domain.matching.dto.response;

import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

@Getter
@Builder
@AllArgsConstructor
public class ApplicantResponse {

    // ─── 매칭 신청 정보 ───
    private Long applicationId;
    private Long tutorId;
    private LocalDateTime appliedAt;
    private ApplicationStatus status;

    // ─── 강사 프로필 (Tutor 엔티티 직접 매핑) ───
    private String name;
    private String school;
    private String major;
    private BigDecimal ratingAvg;
    private int reviewCount;
    private int lessonCount;
    private String bio;
    private String profileImageUrl;

    // ─── 임시 하드코딩 (백엔드 미구현) ───
    private boolean isOnline;
    private int avgResponseMinutes;
    private List<String> subjects;

    public static ApplicantResponse from(MatchingApplication application, Tutor tutor) {
        return ApplicantResponse.builder()
                .applicationId(application.getId())
                .tutorId(application.getTutorId())
                .appliedAt(application.getAppliedAt())
                .status(application.getStatus())
                .name(tutor.getName())
                .school(tutor.getSchool())
                .major(tutor.getMajor())
                .ratingAvg(tutor.getRatingAvg())
                .reviewCount(tutor.getReviewCount())
                .lessonCount(tutor.getLessonCount())
                .bio(tutor.getBio())
                .profileImageUrl(tutor.getProfileImageUrl())
                .isOnline(true)
                .avgResponseMinutes(0)
                .subjects(Collections.emptyList())
                .build();
    }
}
