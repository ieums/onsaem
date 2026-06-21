package com.ieum.backend.domain.lesson.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class RecordingStartResponseDto {
    private Long lessonId;
    private String resourceId;
    private String sid;
    private String channelName;
}
