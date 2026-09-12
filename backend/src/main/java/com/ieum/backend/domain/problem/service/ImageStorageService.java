package com.ieum.backend.domain.problem.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.stream.Collectors;

public interface ImageStorageService {
    String store(MultipartFile file);

    default List<String> storeAll(List<MultipartFile> files) {
        return files.stream()
                .map(this::store)
                .collect(Collectors.toList());
    }

    /** 저장된 이미지 1건 삭제 (실패해도 예외를 던지지 않는 best-effort) */
    void delete(String storedUrl);

    /** 저장된 이미지 일괄 삭제 (AI 실패 등으로 삭제되지 않은 이미지 정리용) */
    default void deleteAll(List<String> storedUrls) {
        if (storedUrls != null) {
            storedUrls.forEach(this::delete);
        }
    }
}