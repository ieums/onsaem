package com.ieum.backend.domain.problem.service;

import com.ieum.backend.global.exception.BusinessException;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Slf4j
@Service
@Profile("local")
public class LocalImageStorageService implements ImageStorageService {

    private final String uploadDir = "uploads";

    @Override
    public String store(MultipartFile file) {
        try {
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            String extension = "";
            String originalFilename = file.getOriginalFilename();
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String storedFilename = UUID.randomUUID() + extension;

            Path filePath = uploadPath.resolve(storedFilename);
            Files.copy(file.getInputStream(), filePath);

            return "/uploads/" + storedFilename;

        } catch (IOException e) {
            throw BusinessException.internalError("이미지 저장 실패", e);
        }
    }

    @Override
    public void delete(String storedUrl) {
        try {
            String filename = storedUrl.substring(storedUrl.lastIndexOf('/') + 1);
            Files.deleteIfExists(Paths.get(uploadDir).resolve(filename));
        } catch (Exception e) {
            log.warn("로컬 이미지 삭제 실패 (무시): {}", storedUrl, e);
        }
    }
}