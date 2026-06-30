package com.ieum.backend.domain.auth.service;

import com.ieum.backend.global.exception.BusinessException;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

/**
 * local 프로필 증빙 저장 — uploads/verifications/ 에 저장하고 "/uploads/verifications/{파일}" 반환.
 * WebConfig가 /uploads/** 를 정적 서빙하므로 관리자는 그 경로로 바로 열람한다.
 */
@Service
@Profile("local")
public class LocalVerificationDocumentStorage implements VerificationDocumentStorage {

    private static final String SUBDIR = "uploads/verifications";

    @Override
    public String store(MultipartFile file) {
        String contentType = file.getContentType();
        boolean allowed = contentType != null && (
                contentType.equals("application/pdf")
                        || contentType.equals("image/jpeg")
                        || contentType.equals("image/png"));
        if (!allowed) {
            throw BusinessException.badRequest("PDF 또는 이미지(JPG/PNG) 파일만 업로드할 수 있습니다.");
        }
        if (file.getSize() > 10L * 1024 * 1024) {
            throw BusinessException.badRequest("증빙 서류는 10MB를 넘을 수 없습니다.");
        }

        try {
            Path dir = Paths.get(SUBDIR);
            if (!Files.exists(dir)) {
                Files.createDirectories(dir);
            }
            String original = file.getOriginalFilename();
            String ext = (original != null && original.contains("."))
                    ? original.substring(original.lastIndexOf('.'))
                    : "";
            String stored = UUID.randomUUID() + ext;
            Files.copy(file.getInputStream(), dir.resolve(stored));
            return "/uploads/verifications/" + stored;
        } catch (IOException e) {
            throw BusinessException.internalError("증빙 서류 저장 실패", e);
        }
    }

    @Override
    public String viewUrl(String storedRef) {
        // 이미 "/uploads/verifications/..." 정적 경로 → 그대로 열람.
        return storedRef;
    }
}
