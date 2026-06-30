package com.ieum.backend.domain.auth.service;

import com.ieum.backend.global.s3.S3Service;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/**
 * prod 프로필 증빙 저장 — S3 비공개 객체. 열람은 presigned URL.
 */
@Service
@Profile("prod")
@RequiredArgsConstructor
public class S3VerificationDocumentStorage implements VerificationDocumentStorage {

    private final S3Service s3Service;

    @Override
    public String store(MultipartFile file) {
        return s3Service.uploadVerificationDocument(file);
    }

    @Override
    public String viewUrl(String storedRef) {
        return s3Service.presignGetUrl(storedRef);
    }
}
