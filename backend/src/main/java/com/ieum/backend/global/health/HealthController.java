package com.ieum.backend.global.health;

import com.ieum.backend.global.response.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 앱 시작 시 서버 연결 확인용 단순 health 엔드포인트.
 * 프론트(health_provider)가 GET /api/v1/health 로 200을 기대하는데
 * 그동안 핸들러가 없어 GlobalExceptionHandler가 500을 반환 → "서버 연결 실패"로 떴다.
 * SecurityConfig permitAll 에 이미 /api/v1/health 가 등록돼 있어 인증 없이 접근 가능.
 */
@RestController
@RequestMapping("/api/v1/health")
public class HealthController {

    @GetMapping
    public ApiResponse<String> health() {
        return ApiResponse.ok("healthy");
    }
}
