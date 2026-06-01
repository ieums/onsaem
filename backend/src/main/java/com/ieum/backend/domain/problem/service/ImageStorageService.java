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
}