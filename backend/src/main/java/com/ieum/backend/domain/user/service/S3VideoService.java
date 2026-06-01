package com.ieum.backend.domain.user.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Uri;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;

import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * S3에 저장된 강의 영상을 OS 임시 파일로 다운로드.
 * 호출자가 사용 후 반드시 Files.deleteIfExists(path)로 정리해야 함.
 */
@Service
@RequiredArgsConstructor
public class S3VideoService {

    private final S3Client s3Client;

    public Path downloadToTempFile(String s3Url) throws IOException {
        S3Uri s3Uri = s3Client.utilities().parseUri(URI.create(s3Url));
        String bucket = s3Uri.bucket()
                .orElseThrow(() -> new IllegalArgumentException("S3 URL에서 bucket 추출 실패: " + s3Url));
        String key = s3Uri.key()
                .orElseThrow(() -> new IllegalArgumentException("S3 URL에서 key 추출 실패: " + s3Url));

        Path tempFile = Files.createTempFile("lesson_", ".mp4");
        Files.deleteIfExists(tempFile);
        s3Client.getObject(
                GetObjectRequest.builder().bucket(bucket).key(key).build(),
                tempFile
        );
        return tempFile;
    }
}