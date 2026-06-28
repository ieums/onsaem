package com.ieum.backend.domain.lessonreview.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.io.IOException;
import java.net.URI;
import java.nio.file.Path;
import java.time.Duration;

/**
 * 운영(S3) 구현. 녹음 다운로드는 기존 S3VideoService에 위임.
 */
@Service
@Profile("prod")
@RequiredArgsConstructor
public class S3LessonMediaStorage implements LessonMediaStorage {

    @Value("${cloud.aws.s3.bucket:onsaem-bucket}")
    private String bucket;

    @Value("${cloud.aws.region.static:ap-northeast-2}")
    private String region;

    @Value("${spring.cloud.aws.credentials.access-key}")
    private String accessKey;

    @Value("${spring.cloud.aws.credentials.secret-key}")
    private String secretKey;

    private final S3Client s3Client;
    private final S3VideoService s3VideoService;

    @Override
    public String defaultRecordingRef(Long lessonId) {
        return null; // Agora Cloud Recording이 stopRecording에서 실제 S3 URL을 세팅
    }

    @Override
    public boolean isRecordingAvailable(Long lessonId, String recordingRef) {
        // prod는 recording_url(S3 URL)이 세팅돼 있으면 존재로 간주(실패 시 기존처럼 fetch에서 처리).
        return recordingRef != null && !recordingRef.isBlank();
    }

    @Override
    public Path fetchRecordingToTemp(Long lessonId, String recordingRef) throws IOException {
        return s3VideoService.downloadToTempFile(recordingRef);
    }

    @Override
    public String storeSummaryPdf(byte[] pdf, Long lessonId) {
        String key = "lessons/summaries/" + lessonId + "/summary.pdf";
        s3Client.putObject(
                PutObjectRequest.builder()
                        .bucket(bucket)
                        .key(key)
                        .contentType("application/pdf")
                        .build(),
                RequestBody.fromBytes(pdf)
        );
        return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + key;
    }

    @Override
    public String recordingPlaybackUrl(Long lessonId, String recordingRef) {
        if (recordingRef == null || recordingRef.isBlank()) return null;
        // raw S3 URL 노출 대신 시간 제한 presigned URL로. (S3가 range/스트리밍 지원)
        return presign(recordingRef);
    }

    @Override
    public Resource openRecordingResource(Long lessonId, String recordingRef) {
        // prod는 presigned URL로 직접 가므로 백엔드 스트리밍 엔드포인트를 타지 않는다.
        throw new UnsupportedOperationException("prod는 presigned URL 재생을 사용합니다.");
    }

    @Override
    public String summaryPdfDownloadUrl(String storedRef) {
        return presign(storedRef);
    }

    private String presign(String s3Url) {
        String key = extractS3Key(s3Url);
        try (S3Presigner presigner = S3Presigner.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKey, secretKey)))
                .build()) {
            GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofHours(1))
                    .getObjectRequest(b -> b.bucket(bucket).key(key))
                    .build();
            return presigner.presignGetObject(presignRequest).url().toString();
        }
    }

    private String extractS3Key(String s3Url) {
        URI uri = URI.create(s3Url);
        String path = uri.getPath();
        return path.startsWith("/") ? path.substring(1) : path;
    }
}
