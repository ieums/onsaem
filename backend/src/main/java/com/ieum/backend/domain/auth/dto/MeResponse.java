package com.ieum.backend.domain.auth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.ieum.backend.domain.auth.entity.Account;
import com.ieum.backend.domain.auth.entity.Role;
import com.ieum.backend.domain.auth.entity.Tutor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** 내 정보 조회 응답 (학생/강사 공통 필드 + 강사 전용 필드). */
public record MeResponse(
        Long id,
        String role,
        String name,
        String email,
        String phone,
        LocalDate birthDate,
        String profileImageUrl,
        String provider,
        String status,
        // 강사 전용 (학생은 null)
        String school,
        String major,
        String bio,
        List<String> subjects,
        String educationStatus,
        Integer experienceYears,
        BigDecimal ratingAvg,
        Integer lessonCount,
        @JsonProperty("isAvailable") Boolean available
) {
    /** 학생용 팩토리 (강사 전용 필드는 null). */
    public static MeResponse of(Account account, Role role) {
        return new MeResponse(
                account.getId(),
                role.name(),
                account.getName(),
                account.getEmail(),
                account.getPhone(),
                account.getBirthDate(),
                account.getProfileImageUrl(),
                account.getProvider() == null ? null : account.getProvider().name(),
                account.getStatus().name(),
                null, null, null, null, null, null, null, null, null
        );
    }

    /** 강사용 팩토리 (강사 전용 필드 포함). */
    public static MeResponse ofTutor(Tutor tutor) {
        return new MeResponse(
                tutor.getId(),
                Role.TUTOR.name(),
                tutor.getName(),
                tutor.getEmail(),
                tutor.getPhone(),
                tutor.getBirthDate(),
                tutor.getProfileImageUrl(),
                tutor.getProvider() == null ? null : tutor.getProvider().name(),
                tutor.getStatus().name(),
                tutor.getSchool(),
                tutor.getMajor(),
                tutor.getBio(),
                tutor.getSubjects(),
                tutor.getEducationStatus() != null ? tutor.getEducationStatus().name() : null,
                tutor.getExperienceYears(),
                tutor.getRatingAvg(),
                tutor.getLessonCount(),
                tutor.isAvailable()
        );
    }
}
