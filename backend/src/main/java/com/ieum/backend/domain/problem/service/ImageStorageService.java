package com.ieum.backend.domain.problem.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Service
public class ImageStorageService {

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    /**
     * 서버에 이미지 저장 후 URL 리턴
     * 나중에 S3로 바꿀 때 이 메서드 내부만 교체
     */
    public String store(MultipartFile file) {
        try {
            // 폴더 없으면 생성
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // 파일명 중복 방지: UUID + 원본 확장자
            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String storedFilename = UUID.randomUUID() + extension;

            // 저장
            Path filePath = uploadPath.resolve(storedFilename);
            Files.copy(file.getInputStream(), filePath);

            return "/uploads/" + storedFilename; // URL 리턴

        } catch (IOException e) {
            throw new RuntimeException("이미지 저장 실패", e);
        }
    }
}