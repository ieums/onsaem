package com.ieum.backend.domain.lesson.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class RecordingStopResponseDto {
    private Long lessonId;
    private String recordingUrl;
    private String uploadingStatus;
}
