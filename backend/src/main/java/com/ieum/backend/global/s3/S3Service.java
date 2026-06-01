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
