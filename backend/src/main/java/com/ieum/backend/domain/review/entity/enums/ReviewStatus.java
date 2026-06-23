package com.ieum.backend.domain.review.entity.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ReviewStatus {

    VISIBLE("노출"),
    HIDDEN("숨김");

    private final String displayName;
}
