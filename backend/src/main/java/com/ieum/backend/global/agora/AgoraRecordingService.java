package com.ieum.backend.global.agora;

import com.ieum.backend.domain.lesson.dto.RecordingStartResponseDto;
import com.ieum.backend.domain.lesson.dto.RecordingStopResponseDto;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.global.config.AgoraConfig;
import com.ieum.backend.global.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Response;
import software.amazon.awssdk.services.s3.model.S3Object;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Agora Cloud Recording REST API 클라이언트
 *
 * 흐름: acquire → start → (수업 진행) → stop
 * 인증: Basic Auth (customerId:customerSecret)
 * 녹화 설정: 오디오 전용 (streamTypes=0), 강사 카메라 제외
 * 저장 경로: S3 lessons/recordings/{lessonId}/
 */
@Service
public class AgoraRecordingService {

    private static final Logger log = LoggerFactory.getLogger(AgoraRecordingService.class);
    private static final String BASE_URL = "https://api.agora.io/v1/apps";
    private static final int RECORDING_TOKEN_EXPIRE = 7200; // 2시간

    private final AgoraConfig agoraConfig;
    private final RestClient restClient;

    @Autowired(required = false)
    private S3Client s3Client;

    @Autowired
    private LessonRepository lessonRepository;

    @Value("${spring.cloud.aws.s3.bucket}")
    private String bucket;

    @Value("${spring.cloud.aws.region.static}")
    private String region;

    @Value("${spring.cloud.aws.credentials.access-key}")
    private String awsAccessKey;

    @Value("${spring.cloud.aws.credentials.secret-key}")
    private String awsSecretKey;

    public AgoraRecordingService(AgoraConfig agoraConfig, RestClient.Builder builder) {
        this.agoraConfig = agoraConfig;
        this.restClient = builder.build();
    }

    // ──────────────────────── 공개 메서드 ────────────────────────

    /**
     * 녹화 시작: acquire → start 순서로 Agora API 호출
     * Lesson 엔티티에 resourceId/sid 저장 (트랜잭션은 호출자가 관리)
     */
    public RecordingStartResponseDto startRecording(Lesson lesson) {
        String channelName = lesson.getChannelName();

        // 녹화봇 토큰 생성 (uid=12345, SUBSCRIBER 역할)
        String token;
        try {
            token = new RtcTokenBuilder2().buildTokenWithUid(
                    agoraConfig.getAppId(),
                    agoraConfig.getAppCertificate(),
                    channelName,
                    12345,
                    RtcTokenBuilder2.Role.ROLE_SUBSCRIBER,
                    RECORDING_TOKEN_EXPIRE,
                    RECORDING_TOKEN_EXPIRE
            );
        } catch (Exception e) {
            throw BusinessException.internalError("녹화 토큰 생성에 실패했습니다.");
        }

        String resourceId = acquireResource(channelName);
        String sid = startRecordingInternal(channelName, token, resourceId, lesson.getId(), lesson.getTutorId());
        lesson.setRecordingInfo(resourceId, sid);

        return new RecordingStartResponseDto(lesson.getId(), resourceId, sid, channelName);
    }

    /**
     * 녹화 중지: Agora stop API만 호출하고 즉시 반환.
     * S3 .m3u8 파일 탐색은 stopRecordingAsync()에서 비동기로 처리.
     * (트랜잭션은 호출자가 관리)
     */
    public RecordingStopResponseDto stopRecording(Lesson lesson) {
        log.info("[Agora] stopRecording 호출됨 - lessonId={}, resourceId={}, sid={}", lesson.getId(), lesson.getResourceId(), lesson.getRecordingSid());
        String resourceId = lesson.getResourceId();
        String sid = lesson.getRecordingSid();

        if (resourceId == null || sid == null) {
            throw BusinessException.badRequest("진행 중인 녹화가 없습니다.");
        }

        String[] result = stopRecordingInternal(lesson.getChannelName(), resourceId, sid, lesson.getId());
        String recordingUrl = result[0];
        String uploadingStatus = result[1];

        if (!recordingUrl.isEmpty()) {
            lesson.setRecordingUrl(recordingUrl);
        }

        return new RecordingStopResponseDto(lesson.getId(), recordingUrl, uploadingStatus);
    }

    /**
     * 비동기 S3 폴링: Agora 업로드 완료 후 .m3u8 파일 URL을 DB에 저장.
     * LessonService.stopRecording()에서 호출 — 메인 트랜잭션과 독립 실행.
     */
    @Async
    @Transactional
    public void stopRecordingAsync(Long lessonId) {
        log.info("[Agora][비동기] S3 폴링 시작 - lessonId={}", lessonId);
        String recordingUrl = findM3u8FromS3(lessonId);
        if (!recordingUrl.isEmpty()) {
            lessonRepository.findById(lessonId).ifPresent(lesson -> {
                lesson.setRecordingUrl(recordingUrl);
            });
            log.info("[Agora][비동기] recordingUrl 저장 완료 - lessonId={}, url={}", lessonId, recordingUrl);
        } else {
            log.warn("[Agora][비동기] S3 .m3u8 최종 미발견 - lessonId={}", lessonId);
        }
    }

    // ──────────────────────── Private API 헬퍼 ────────────────────────

    /** 리소스 ID 획득 */
    private String acquireResource(String channelName) {
        String url = BASE_URL + "/" + agoraConfig.getAppId() + "/cloud_recording/acquire";

        Map<String, Object> body = Map.of(
                "cname", channelName,
                "uid", "12345",
                "clientRequest", Map.of()
        );

        Map<String, Object> response = post(url, body);
        String resourceId = (String) response.get("resourceId");
        if (resourceId == null) {
            throw BusinessException.internalError("녹화 리소스 획득에 실패했습니다.");
        }
        return resourceId;
    }

    /** 녹화 시작 — SID 반환 */
    private String startRecordingInternal(String channelName, String token,
                                          String resourceId, Long lessonId, Long tutorUid) {
        String url = BASE_URL + "/" + agoraConfig.getAppId()
                + "/cloud_recording/resourceid/" + resourceId + "/mode/mix/start";

        // 오디오+비디오 녹화 설정 (화이트보드 커스텀 비디오 소스 포함)
        Map<String, Object> recordingConfig = new HashMap<>();
        recordingConfig.put("maxIdleTime", 30);
        recordingConfig.put("streamTypes", 3);
        recordingConfig.put("channelType", 0);
        recordingConfig.put("videoStreamType", 0);
        recordingConfig.put("subscribeVideoUids", List.of(String.valueOf(tutorUid)));
        recordingConfig.put("subscribeAudioUids", List.of(String.valueOf(tutorUid)));
        recordingConfig.put("subscribeUidGroup", 0);

        // S3 저장 설정
        Map<String, Object> storageConfig = new HashMap<>();
        storageConfig.put("vendor", 1);                                 // 1=Amazon S3
        storageConfig.put("region", 10);                                // 10=ap-northeast-2 (Seoul)
        storageConfig.put("bucket", bucket);
        storageConfig.put("accessKey", awsAccessKey);
        storageConfig.put("secretKey", awsSecretKey);
        storageConfig.put("fileNamePrefix",
                List.of("lessons", "recordings", String.valueOf(lessonId)));

        Map<String, Object> transcodingConfig = new HashMap<>();
        transcodingConfig.put("width", 1280);
        transcodingConfig.put("height", 720);
        transcodingConfig.put("fps", 15);
        transcodingConfig.put("bitrate", 1000);
        transcodingConfig.put("mixedVideoLayout", 1);                   // 1=bestFit

        Map<String, Object> clientRequest = new HashMap<>();
        clientRequest.put("token", token);
        clientRequest.put("recordingConfig", recordingConfig);
        clientRequest.put("transcodingConfig", transcodingConfig);
        clientRequest.put("storageConfig", storageConfig);

        Map<String, Object> body = new HashMap<>();
        body.put("cname", channelName);
        body.put("uid", "12345");
        body.put("clientRequest", clientRequest);

        log.info("[Agora] startRecording 요청 body - cname={}, uid=12345, recordingConfig={}, transcodingConfig={}",
                channelName, recordingConfig, transcodingConfig);

        Map<String, Object> response = post(url, body);
        String sid = (String) response.get("sid");
        if (sid == null) {
            throw BusinessException.internalError("녹화 시작에 실패했습니다.");
        }
        return sid;
    }

    /** 녹화 중지 — [recordingUrl, uploadingStatus] 반환 */
    @SuppressWarnings("unchecked")
    private String[] stopRecordingInternal(String channelName, String resourceId, String sid, Long lessonId) {
        log.info("[Agora] stopRecordingInternal 호출됨 - channelName={}, resourceId={}, sid={}", channelName, resourceId, sid);
        String url = BASE_URL + "/" + agoraConfig.getAppId()
                + "/cloud_recording/resourceid/" + resourceId
                + "/sid/" + sid + "/mode/mix/stop";

        Map<String, Object> body = Map.of(
                "cname", channelName,
                "uid", "12345",
                "clientRequest", Map.of()
        );

        Map<String, Object> response = post(url, body);
        Map<String, Object> serverResponse = (Map<String, Object>) response.get("serverResponse");
        if (serverResponse == null) {
            throw BusinessException.internalError("녹화 중지 응답이 올바르지 않습니다.");
        }

        String uploadingStatus = (String) serverResponse.getOrDefault("uploadingStatus", "unknown");
        String recordingUrl = "";

        Object fileListObj = serverResponse.get("fileList");
        if (fileListObj instanceof List) {
            List<Map<String, Object>> fileList = (List<Map<String, Object>>) fileListObj;
            if (!fileList.isEmpty()) {
                String filename = (String) fileList.get(0).get("filename");
                if (filename != null) {
                    recordingUrl = "https://" + bucket + ".s3." + region
                            + ".amazonaws.com/" + filename;
                }
            }
        }

        if (recordingUrl.isEmpty()) {
            log.info("[Agora] stop 응답에 fileList 없음 — 비동기 S3 폴링으로 처리 예정, lessonId={}", lessonId);
        }

        log.info("[Agora] stop 응답 - uploadingStatus={}, recordingUrl={}", uploadingStatus, recordingUrl);
        return new String[]{recordingUrl, uploadingStatus};
    }

    /** S3 ListObjectsV2로 lessons/recordings/{lessonId}/ 경로에서 .m3u8 파일을 찾아 URL 반환
     *  최대 10회, 3초 간격으로 폴링 — Agora 업로드 완료까지 대기 */
    private String findM3u8FromS3(Long lessonId) {
        if (s3Client == null) {
            log.warn("[Agora] S3Client 미주입 상태 (prod 프로파일 아님) — S3 탐색 생략");
            return "";
        }
        String prefix = "lessons/recordings/" + lessonId + "/";
        int maxAttempts = 10;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                ListObjectsV2Response listResponse = s3Client.listObjectsV2(
                        ListObjectsV2Request.builder()
                                .bucket(bucket)
                                .prefix(prefix)
                                .build()
                );
                for (S3Object object : listResponse.contents()) {
                    if (object.key().endsWith(".m3u8")) {
                        String resolvedUrl = "https://" + bucket + ".s3." + region
                                + ".amazonaws.com/" + object.key();
                        log.info("[Agora] S3에서 .m3u8 파일 발견 (시도 {}/{}) - {}", attempt, maxAttempts, resolvedUrl);
                        return resolvedUrl;
                    }
                }
                log.info("[Agora] S3 .m3u8 파일 없음 (시도 {}/{}) - prefix={}", attempt, maxAttempts, prefix);
                if (attempt < maxAttempts) {
                    Thread.sleep(3000);
                }
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                log.warn("[Agora] S3 폴링 인터럽트 - lessonId={}", lessonId);
                break;
            } catch (Exception e) {
                log.error("[Agora] S3 ListObjects 실패 (시도 {}/{}) - prefix={}, error={}", attempt, maxAttempts, prefix, e.getMessage());
                if (attempt < maxAttempts) {
                    try { Thread.sleep(3000); } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            }
        }
        log.warn("[Agora] S3 .m3u8 파일 최종 미발견 - lessonId={}", lessonId);
        return "";
    }

    // ──────────────────────── HTTP 공통 ────────────────────────

    private Map<String, Object> post(String url, Object body) {
        return restClient.post()
                .uri(url)
                .header("Authorization", "Basic " + basicAuth())
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .onStatus(
                        status -> status.isError(),
                        (req, res) -> {
                            byte[] bytes = res.getBody() != null ? res.getBody().readAllBytes() : new byte[0];
                            String errorBody = bytes.length > 0 ? new String(bytes, StandardCharsets.UTF_8) : "(empty body)";
                            log.error("[Agora] API 오류 — url={} status={} body={}", req.getURI(), res.getStatusCode(), errorBody);
                            throw BusinessException.internalError(
                                    "Agora Recording API 오류: " + res.getStatusCode());
                        }
                )
                .body(new ParameterizedTypeReference<>() {});
    }

    /** Basic 인증 헤더 값 생성 */
    private String basicAuth() {
        String credentials = agoraConfig.getCustomerId() + ":" + agoraConfig.getCustomerSecret();
        return Base64.getEncoder().encodeToString(credentials.getBytes(StandardCharsets.UTF_8));
    }
}
