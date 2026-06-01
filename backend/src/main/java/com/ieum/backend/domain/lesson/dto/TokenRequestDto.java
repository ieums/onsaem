package com.ieum.backend.domain.lesson.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class TokenRequestDto {

    @NotBlank(message = "채널 이름은 필수입니다.")
    private String channelName;

    private String uid = "0";

    private String role = "PUBLISHER";
}
