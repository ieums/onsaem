package com.ieum.backend.domain.problem.service;

import com.ieum.backend.global.exception.BusinessException;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.util.UUID;

@Slf4j
@Service
@Profile("prod")
public class S3ImageStorageService implements ImageStorageService {

    private final S3Client s3Client;

    @Value("${spring.cloud.aws.s3.bucket}")
    private String bucket;

    public S3ImageStorageService(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    @Override
    public String store(MultipartFile file) {
        try {
            // 실제 바이트로 타입을 판별한다. 클라이언트가 준 content-type/확장자는
            // 자주 틀려서(예: PNG를 image/jpeg + .jpg로) 그대로 믿으면 S3가 거짓 Content-Type을
            // 돌려주고, 그걸 신뢰하는 소비자(복습 PDF 렌더러 등)에서 이미지가 깨진다.
            byte[] bytes = file.getBytes();
            String sniffed = sniffImageMime(bytes);
            String contentType = sniffed != null ? sniffed : fallbackContentType(file);
            String extension = extensionFor(contentType, file.getOriginalFilename());
            String key = "problems/" + UUID.randomUUID() + extension;

            PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(contentType)
                    .build();

            s3Client.putObject(request, RequestBody.fromBytes(bytes));

            return "https://" + bucket + ".s3.ap-northeast-2.amazonaws.com/" + key;

        } catch (IOException e) {
            throw BusinessException.internalError("S3 업로드 실패", e);
        }
    }

    /** 매직넘버로 이미지 MIME 판별. 모르면 null. */
    private static String sniffImageMime(byte[] b) {
        if (b == null || b.length < 12) return null;
        if ((b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') return "image/png";
        if ((b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) return "image/jpeg";
        if (b[0] == 'G' && b[1] == 'I' && b[2] == 'F' && b[3] == '8') return "image/gif";
        if (b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return "image/webp";
        if (b[0] == 'B' && b[1] == 'M') return "image/bmp";
        return null;
    }

    private static String fallbackContentType(MultipartFile file) {
        String ct = file.getContentType();
        return (ct != null && ct.startsWith("image/")) ? ct : "application/octet-stream";
    }

    /** Content-Type 우선으로 확장자 결정. 못 정하면 원본 확장자, 그것도 없으면 빈 문자열. */
    private static String extensionFor(String contentType, String originalFilename) {
        switch (contentType) {
            case "image/png": return ".png";
            case "image/jpeg": return ".jpg";
            case "image/gif": return ".gif";
            case "image/webp": return ".webp";
            case "image/bmp": return ".bmp";
            default:
                if (originalFilename != null && originalFilename.contains(".")) {
                    return originalFilename.substring(originalFilename.lastIndexOf("."));
                }
                return "";
        }
    }

    @Override
    public void delete(String storedUrl) {
        try {
            // URL에서 key 추출: https://{bucket}.s3....amazonaws.com/{key}
            String key = storedUrl.substring(storedUrl.indexOf(".amazonaws.com/") + ".amazonaws.com/".length());
            s3Client.deleteObject(DeleteObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .build());
        } catch (Exception e) {
            log.warn("S3 이미지 삭제 실패 (무시): {}", storedUrl, e);
        }
    }
}