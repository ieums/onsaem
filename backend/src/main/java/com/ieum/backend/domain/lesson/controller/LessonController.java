package com.ieum.backend.domain.lesson.controller;

import com.ieum.backend.domain.lesson.dto.TokenRequestDto;
import com.ieum.backend.domain.lesson.dto.TokenResponseDto;
import com.ieum.backend.domain.lesson.service.LessonService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/lesson")
@RequiredArgsConstructor
public class LessonController {

    private final LessonService lessonService;

    @PostMapping("/token")
    public ApiResponse<TokenResponseDto> generateToken(@RequestBody @Valid TokenRequestDto req) {
        return ApiResponse.ok(lessonService.generateToken(req));
    }
}
