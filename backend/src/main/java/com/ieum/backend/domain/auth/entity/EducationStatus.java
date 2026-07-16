package com.ieum.backend.domain.auth.entity;

import com.ieum.backend.global.exception.BusinessException;
import java.util.Arrays;

/** 강사 최종학력 상태. 프론트 표시 라벨(재학중 등)과 매핑. */
public enum EducationStatus {
    ENROLLED("재학"),
    ON_LEAVE("휴학"),
    GRADUATED("졸업");

    private final String label;

    EducationStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /** 프론트가 보낸 한글 라벨 → enum 변환. 매칭 실패 시 400. */
    public static EducationStatus fromLabel(String label) {
        return Arrays.stream(values())
                .filter(e -> e.label.equals(label))
                .findFirst()
                .orElseThrow(() -> BusinessException.badRequest("올바르지 않은 최종학력입니다: " + label));
    }
}