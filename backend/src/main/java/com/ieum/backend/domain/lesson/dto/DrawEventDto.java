package com.ieum.backend.domain.lesson.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class DrawEventDto {
    /** 이벤트 타입: DRAW | ERASE | CLEAR | IMAGE_ADD | UNDO | REDO | CAMERA_ON | CAMERA_OFF */
    private String type;
    private Double x;
    private Double y;
    private String color;
    private Double strokeWidth;
    /** IMAGE_ADD 타입일 때 사용하는 이미지 URL */
    private String imageUrl;
    /** 에코 필터링용 — 자신이 보낸 이벤트를 수신 측에서 무시하기 위해 사용 */
    private String senderId;
    /** 새 스트로크 시작 여부 — 동일 색상/굵기 연속 드로잉 시 스트로크 끊김 수정용 */
    private Boolean isStart;
    /** Undo 동기화용 스트로크 고유 ID */
    private String strokeId;
}
