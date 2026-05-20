package com.ieum.backend.domain.lesson.controller;

import com.ieum.backend.domain.lesson.dto.LessonImageResponseDto;
import com.ieum.backend.domain.lesson.dto.TokenRequestDto;
import com.ieum.backend.domain.lesson.dto.TokenResponseDto;
import com.ieum.backend.domain.lesson.service.LessonService;
import com.ieum.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/lesson")
@RequiredArgsConstructor
public class LessonController {

    private final LessonService lessonService;

    /**
     * Agora 토큰 발급
     * POST /api/v1/lesson/token
     */
    @PostMapping("/token")
    public ApiResponse<TokenResponseDto> generateToken(@RequestBody @Valid TokenRequestDto req) {
        return ApiResponse.ok(lessonService.generateToken(req));
    }

    /**
     * 수업 중 임시 이미지 업로드
     * POST /api/v1/lesson/{lessonId}/images
     */
    @PostMapping("/{lessonId}/images")
    public ApiResponse<LessonImageResponseDto> uploadImage(
            @PathVariable Long lessonId,
            @RequestPart("file") MultipartFile file) {
        return ApiResponse.ok(lessonService.uploadTempImage(lessonId, file));
    }

    /**
     * 수업 완료 (임시 이미지 자동 삭제)
     * POST /api/v1/lesson/{lessonId}/complete
     */
    @PostMapping("/{lessonId}/complete")
    public ApiResponse<Void> completeLesson(
            @PathVariable Long lessonId,
            @RequestParam(required = false) String recordingUrl) {
        lessonService.completeLesson(lessonId, recordingUrl);
        return ApiResponse.ok("수업이 완료되었습니다.", null);
    }
}
