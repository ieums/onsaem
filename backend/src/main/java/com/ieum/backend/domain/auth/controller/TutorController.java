package com.ieum.backend.domain.auth.controller;

import com.ieum.backend.domain.auth.dto.TutorAvailabilityRequest;
import com.ieum.backend.domain.auth.service.TutorService;
import com.ieum.backend.global.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/tutors")
@RequiredArgsConstructor
public class TutorController {

    private final TutorService tutorService;

    @PatchMapping("/{tutorId}/availability")
    public ApiResponse<Void> updateAvailability(
            @PathVariable Long tutorId,
            @RequestBody TutorAvailabilityRequest request) {
        tutorService.updateAvailability(tutorId, request.available());
        return ApiResponse.ok("가용 상태가 업데이트되었습니다.", null);
    }
}
