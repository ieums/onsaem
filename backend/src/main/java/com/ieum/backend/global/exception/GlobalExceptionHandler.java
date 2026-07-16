package com.ieum.backend.global.exception;

import com.ieum.backend.global.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusiness(BusinessException e) {
        // 5xx(서버/외부연동 오류)는 원인까지 로깅, 4xx(클라이언트 잘못)는 메시지만(일시적으로 수정)
        if (e.getStatus().is5xxServerError()) {
            log.error("[BusinessException] {}", e.getMessage(), e);
        } else {
            log.warn("[BusinessException] {} - {}", e.getStatus(), e.getMessage(),e);
        }
        return ResponseEntity.status(e.getStatus()).body(ApiResponse.fail(e.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .orElse("잘못된 요청입니다.");
        return ResponseEntity.badRequest().body(ApiResponse.fail(message));
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<ApiResponse<Void>> handleIllegalState(IllegalStateException e) {
        return ResponseEntity.badRequest().body(ApiResponse.fail(e.getMessage()));
    }

    /**
     * 존재하지 않는 정적 리소스 요청(예: 로컬 uploads/ 에 없는 옛 이미지) — 스택트레이스 없이 404.
     * (다른 환경에서 올린 이미지 URL을 로컬에서 열 때 흔히 발생하는 무해한 404)
     */
    @ExceptionHandler(org.springframework.web.servlet.resource.NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNoResource(
            org.springframework.web.servlet.resource.NoResourceFoundException e) {
        log.debug("[NoResource] 정적 리소스 없음: {}", e.getResourcePath());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.fail("리소스를 찾을 수 없습니다."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleException(Exception e) {
        // 미처리 예외는 반드시 스택트레이스를 남겨 원인을 추적할 수 있게 한다
        log.error("[Unhandled] 처리되지 않은 예외", e);
        return ResponseEntity.internalServerError().body(ApiResponse.fail("서버 오류가 발생했습니다."));
    }
}
