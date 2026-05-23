package com.ieum.backend.domain.lesson.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class TokenResponseDto {
    private Long lessonId;
    private String token;
    private String channelName;
    private String appId;
    private long expireAt;
}
