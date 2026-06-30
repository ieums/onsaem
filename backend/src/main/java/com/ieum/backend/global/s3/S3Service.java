package com.ieum.backend.global.s3;

import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.IOException;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class S3Service {

    private final S3Client s3Client;

    @Value("${spring.cloud.aws.s3.bucket}")
    private String bucket;

    @Value("${spring.cloud.aws.region.static}")
    private String region;

    /**
     * 수업 임시 이미지 업로드
     * 저장 경로: lessons/temp/{lessonId}/{UUID}_{originalFilename}
     */
    public String uploadTempImage(Long lessonId, MultipartFile file) {
        String originalFilename = file.getOriginalFilename() != null
                ? file.getOriginalFilename().replaceAll("[^a-zA-Z0-9._-]", "_")
                : "image";
        String key = "lessons/temp/" + lessonId + "/" + UUID.randomUUID() + "_" + originalFilename;

        try {
            s3Client.putObject(
                    PutObjectRequest.builder()
                            .bucket(bucket)
                            .key(key)
                            .contentType(file.getContentType())
                            .contentLength(file.getSize())
                            .build(),
                    RequestBody.fromInputStream(file.getInputStream(), file.getSize())
            );
        } catch (IOException e) {
            throw BusinessException.internalError("이미지 업로드에 실패했습니다.");
        }

        return String.format("https://%s.s3.%s.amazonaws.com/%s", bucket, region, key);
    }
    /**
     * 강사 학력 증빙 서류 업로드 (PDF/이미지).
     * 저장 경로: tutor-verifications/{UUID}_{originalFilename}
     * 가입 시점이라 tutorId가 없어 UUID로 식별한다. (private 객체 → 조회는 presign 필요)
     */
    public String uploadVerificationDocument(MultipartFile file) {
        // 1) 형식 검증 — PDF / JPG / PNG 만 허용
        String contentType = file.getContentType();
        boolean allowed = contentType != null && (
                contentType.equals("application/pdf")
                        || contentType.equals("image/jpeg")
                        || contentType.equals("image/png"));
        if (!allowed) {
            throw BusinessException.badRequest("PDF 또는 이미지(JPG/PNG) 파일만 업로드할 수 있습니다.");
        }

        // 2) 크기 제한 — 10MB
        long maxSize = 10L * 1024 * 1024;
        if (file.getSize() > maxSize) {
            throw BusinessException.badRequest("증빙 서류는 10MB를 넘을 수 없습니다.");
        }

        // 3) 키 생성 + 업로드
        String originalFilename = file.getOriginalFilename() != null
                ? file.getOriginalFilename().replaceAll("[^a-zA-Z0-9._-]", "_")
                : "document";
        String key = "tutor-verifications/" + UUID.randomUUID() + "_" + originalFilename;

        try {
            s3Client.putObject(
                    PutObjectRequest.builder()
                            .bucket(bucket)
                            .key(key)
                            .contentType(contentType)
                            .contentLength(file.getSize())
                            .build(),
                    RequestBody.fromInputStream(file.getInputStream(), file.getSize())
            );
        } catch (IOException e) {
            throw BusinessException.internalError("증빙 서류 업로드에 실패했습니다.");
        }

        return String.format("https://%s.s3.%s.amazonaws.com/%s", bucket, region, key);
    }

    /**
     * 수업 종료 시 해당 lessonId의 임시 이미지 전체 삭제
     * 접두사: lessons/temp/{lessonId}/
     */
    public void deleteTempImages(Long lessonId) {
        String prefix = "lessons/temp/" + lessonId + "/";

        ListObjectsV2Response listResponse = s3Client.listObjectsV2(
                ListObjectsV2Request.builder()
                        .bucket(bucket)
                        .prefix(prefix)
                        .build()
        );

        List<S3Object> objects = listResponse.contents();
        if (objects.isEmpty()) {
            return;
        }

        List<ObjectIdentifier> toDelete = objects.stream()
                .map(obj -> ObjectIdentifier.builder().key(obj.key()).build())
                .collect(Collectors.toList());

        s3Client.deleteObjects(
                DeleteObjectsRequest.builder()
                        .bucket(bucket)
                        .delete(Delete.builder().objects(toDelete).build())
                        .build()
        );
    }
}
