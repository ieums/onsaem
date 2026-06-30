package com.ieum.backend.domain.auth.service;

import org.springframework.web.multipart.MultipartFile;

/**
 * 강사 학력 증빙 서류 저장소 — 프로필별 구현.
 * - local : 작업 디렉터리 uploads/verifications/ 에 저장하고 "/uploads/verifications/{파일}" 반환(정적 서빙).
 * - prod  : S3 비공개 객체로 저장하고, 열람은 presigned URL.
 *
 * 문제·프로필 이미지의 {@code ImageStorageService}와 동일한 패턴이되, 증빙은 prod에서 '비공개'라는 점만 다르다.
 */
public interface VerificationDocumentStorage {

    /** 증빙 서류 저장 → 저장 참조(URL 또는 경로) 반환. */
    String store(MultipartFile file);

    /** 관리자 열람용 URL — local은 정적 경로 그대로, prod는 presigned URL. */
    String viewUrl(String storedRef);
}
