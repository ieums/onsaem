package com.ieum.backend.domain.lesson.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class DrawEventDto {
    /** 이벤트 타입: DRAW | ERASE | CLEAR | IMAGE_ADD */
    private String type;
    private Double x;
    private Double y;
    private String color;
    private Double strokeWidth;
    /** IMAGE_ADD 타입일 때 사용하는 이미지 URL */
    private String imageUrl;
}
