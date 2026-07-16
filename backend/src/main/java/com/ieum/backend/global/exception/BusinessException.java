package com.ieum.backend.global.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class BusinessException extends RuntimeException {
    private final HttpStatus status;
    private final String code;

    private BusinessException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    private BusinessException(HttpStatus status, String code, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
        this.code = code;
    }

    // 404 — 리소스 없음
    public static BusinessException notFound(String message) {
        return new BusinessException(HttpStatus.NOT_FOUND, "NOT_FOUND", message);
    }

    // 400 — 잘못된 요청 / 비즈니스 규칙 위반
    public static BusinessException badRequest(String message) {
        return new BusinessException(HttpStatus.BAD_REQUEST, "BAD_REQUEST", message);
    }

    // 403 — 권한 없음 (본인 리소스 아님 등)
    public static BusinessException forbidden(String message) {
        return new BusinessException(HttpStatus.FORBIDDEN, "FORBIDDEN", message);
    }

    // 409 — 상태 충돌 (중복 생성, 이미 처리됨 등)
    public static BusinessException conflict(String message) {
        return new BusinessException(HttpStatus.CONFLICT, "CONFLICT", message);
    }

    public static BusinessException conflict(String message, Throwable cause) {
        return new BusinessException(HttpStatus.CONFLICT, "CONFLICT", message, cause);
    }

    // 500 — 내부/외부 연동 오류
    public static BusinessException unauthorized(String message) {
        return new BusinessException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", message);
    }

    public static BusinessException internalError(String message) {
        return new BusinessException(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", message);
    }

    public static BusinessException internalError(String message, Throwable cause) {
        return new BusinessException(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", message, cause);
    }

    /** 외부 서비스 과부하 등 일시적 사용 불가(503). 보통 잠시 후 재시도 안내용. */
    public static BusinessException serviceUnavailable(String message, Throwable cause) {
        return new BusinessException(HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_UNAVAILABLE", message, cause);
    }
}
