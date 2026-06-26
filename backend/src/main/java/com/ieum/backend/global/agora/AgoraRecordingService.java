package com.ieum.backend.global.agora;

import com.ieum.backend.domain.lesson.dto.RecordingStartResponseDto;
import com.ieum.backend.domain.lesson.dto.RecordingStopResponseDto;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.global.config.AgoraConfig;
import com.ieum.backend.global.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

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

        // 녹화봇 토큰 생성 (uid=0, SUBSCRIBER 역할)
        String token;
        try {
            token = new RtcTokenBuilder2().buildTokenWithUid(
                    agoraConfig.getAppId(),
                    agoraConfig.getAppCertificate(),
                    channelName,
                    0,
                    RtcTokenBuilder2.Role.ROLE_SUBSCRIBER,
                    RECORDING_TOKEN_EXPIRE,
                    RECORDING_TOKEN_EXPIRE
            );
        } catch (Exception e) {
            throw BusinessException.internalError("녹화 토큰 생성에 실패했습니다.");
        }

        String resourceId = acquireResource(channelName);
        String sid = startRecordingInternal(channelName, token, resourceId, lesson.getId());
        lesson.setRecordingInfo(resourceId, sid);

        return new RecordingStartResponseDto(lesson.getId(), resourceId, sid, channelName);
    }

    /**
     * 녹화 중지: stop API 호출 후 Lesson 엔티티에 recordingUrl 저장
     * (트랜잭션은 호출자가 관리)
     */
    public RecordingStopResponseDto stopRecording(Lesson lesson) {
        log.info("[Agora] stopRecording 호출됨 - lessonId={}, resourceId={}, sid={}", lesson.getId(), lesson.getResourceId(), lesson.getRecordingSid());
        String resourceId = lesson.getResourceId();
        String sid = lesson.getRecordingSid();

        if (resourceId == null || sid == null) {
            throw BusinessException.badRequest("진행 중인 녹화가 없습니다.");
        }

        String[] result = stopRecordingInternal(lesson.getChannelName(), resourceId, sid);
        String recordingUrl = result[0];
        String uploadingStatus = result[1];

        lesson.setRecordingUrl(recordingUrl);

        return new RecordingStopResponseDto(lesson.getId(), recordingUrl, uploadingStatus);
    }

    // ──────────────────────── Private API 헬퍼 ────────────────────────

    /** 리소스 ID 획득 */
    private String acquireResource(String channelName) {
        String url = BASE_URL + "/" + agoraConfig.getAppId() + "/cloud_recording/acquire";

        Map<String, Object> body = Map.of(
                "cname", channelName,
                "uid", "0",
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
                                          String resourceId, Long lessonId) {
        String url = BASE_URL + "/" + agoraConfig.getAppId()
                + "/cloud_recording/resourceid/" + resourceId + "/mode/mix/start";

        // 오디오+비디오 녹화 설정 (화이트보드 커스텀 비디오 소스 포함)
        Map<String, Object> recordingConfig = new HashMap<>();
        recordingConfig.put("maxIdleTime", 30);
        recordingConfig.put("streamTypes", 3);                          // 3=오디오+비디오
        recordingConfig.put("channelType", 0);
        recordingConfig.put("subscribeUids", List.of("#allstream#"));

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
        body.put("uid", "0");
        body.put("clientRequest", clientRequest);

        Map<String, Object> response = post(url, body);
        String sid = (String) response.get("sid");
        if (sid == null) {
            throw BusinessException.internalError("녹화 시작에 실패했습니다.");
        }
        return sid;
    }

    /** 녹화 중지 — [recordingUrl, uploadingStatus] 반환 */
    @SuppressWarnings("unchecked")
    private String[] stopRecordingInternal(String channelName, String resourceId, String sid) {
        log.info("[Agora] stopRecordingInternal 호출됨 - channelName={}, resourceId={}, sid={}", channelName, resourceId, sid);
        String url = BASE_URL + "/" + agoraConfig.getAppId()
                + "/cloud_recording/resourceid/" + resourceId
                + "/sid/" + sid + "/mode/mix/stop";

        Map<String, Object> body = Map.of(
                "cname", channelName,
                "uid", "0",
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

        // stop 응답에 파일 목록이 없으면 query API로 재조회
        if (recordingUrl.isEmpty()) {
            log.info("[Agora] stop 응답에 fileList 없음 — query API로 재조회");
            recordingUrl = queryRecordingUrl(resourceId, sid);
        }

        log.info("[Agora] stop 응답 - uploadingStatus={}, recordingUrl={}", uploadingStatus, recordingUrl);
        return new String[]{recordingUrl, uploadingStatus};
    }

    /** query API로 녹화 파일 URL 조회 — stop 응답에 fileList가 없을 때 폴백으로 사용. 최대 10회 재시도(5초 간격). */
    @SuppressWarnings("unchecked")
    private String queryRecordingUrl(String resourceId, String sid) {
        String url = BASE_URL + "/" + agoraConfig.getAppId()
                + "/cloud_recording/resourceid/" + resourceId
                + "/sid/" + sid + "/mode/mix/query";

        for (int attempt = 1; attempt <= 10; attempt++) {
            log.info("[Agora] query 재시도 {}/10", attempt);
            try {
                Map<String, Object> response = get(url);
                Map<String, Object> serverResponse = (Map<String, Object>) response.get("serverResponse");
                if (serverResponse == null) {
                    log.warn("[Agora] query 응답에 serverResponse 없음 (시도 {}/10)", attempt);
                } else {
                    Object fileListObj = serverResponse.get("fileList");
                    if (fileListObj instanceof List) {
                        List<Map<String, Object>> fileList = (List<Map<String, Object>>) fileListObj;
                        for (Map<String, Object> file : fileList) {
                            String filename = (String) file.get("filename");
                            if (filename != null && filename.endsWith(".m3u8")) {
                                String resolvedUrl = "https://" + bucket + ".s3." + region
                                        + ".amazonaws.com/" + filename;
                                log.info("[Agora] query API에서 .m3u8 파일 발견 (시도 {}/10) - {}", attempt, resolvedUrl);
                                return resolvedUrl;
                            }
                        }
                        log.warn("[Agora] query fileList에 .m3u8 파일 없음 (시도 {}/10) - fileList={}", attempt, fileList);
                    } else {
                        log.warn("[Agora] query 응답에 fileList 없음 (시도 {}/10)", attempt);
                    }
                }
            } catch (Exception e) {
                log.error("[Agora] query API 호출 실패 (시도 {}/10) - resourceId={}, sid={}, error={}", attempt, resourceId, sid, e.getMessage());
            }

            if (attempt < 10) {
                try {
                    Thread.sleep(5000);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    log.warn("[Agora] query 재시도 대기 중 인터럽트 발생");
                    return "";
                }
            }
        }

        log.error("[Agora] query API 10회 재시도 모두 실패 - resourceId={}, sid={}", resourceId, sid);
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
                            String errorBody = new String(res.getBody().readAllBytes(), StandardCharsets.UTF_8);
                            log.error("[Agora] API 오류 — url={} status={} body={}", req.getURI(), res.getStatusCode(), errorBody);
                            throw BusinessException.internalError(
                                    "Agora Recording API 오류: " + res.getStatusCode());
                        }
                )
                .body(new ParameterizedTypeReference<>() {});
    }

    private Map<String, Object> get(String url) {
        return restClient.get()
                .uri(url)
                .header("Authorization", "Basic " + basicAuth())
                .retrieve()
                .onStatus(
                        status -> status.isError(),
                        (req, res) -> {
                            String errorBody = new String(res.getBody().readAllBytes(), StandardCharsets.UTF_8);
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
