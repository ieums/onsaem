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
    private Long studentId;   // 강의 종료 후 강사가 학생을 신고/식별할 때
    private Long tutorId;     // 강의 종료 후 학생이 강사를 리뷰/신고할 때
}
