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
 * Agora Cloud Recording REST API 클라이언트 — Web Page Recording(web 모드)
 *
 * 흐름: acquire(scene=1) → start(mode/web) → (수업 진행) → stop(mode/web)
 * 인증: Basic Auth (customerId:customerSecret)
 * 녹화 방식: 녹화봇이 recorder.html을 Chrome으로 열어 화이트보드 화면을 그대로 녹화
 * 저장 경로: S3 lessons/recordings/{lessonId}/
 */
@Service
public class AgoraRecordingService {

    private static final Logger log = LoggerFactory.getLogger(AgoraRecordingService.class);
    private static final String BASE_URL = "https://api.agora.io/v1/apps";

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

    // 녹화 사용 여부. 로컬은 기본 false(S3 없음) → 녹화/폴링 전부 생략. prod yml에서 true로.
    @Value("${agora.recording.enabled:false}")
    private boolean recordingEnabled;

    public AgoraRecordingService(AgoraConfig agoraConfig, RestClient.Builder builder) {
        this.agoraConfig = agoraConfig;
        this.restClient = builder.build();
    }

    // ──────────────────────── 공개 메서드 ────────────────────────

    /**
     * 녹화 시작: acquire → start 순서로 Agora API 호출
     * Lesson 엔티티에 resourceId/sid 저장 (트랜잭션은 호출자가 관리)
     */
    public RecordingStartResponseDto startRecording(Lesson lesson, String orientation) {
        String channelName = lesson.getChannelName();

        // 녹화 비활성(로컬 등) → Agora/S3 호출 없이 무해하게 반환.
        if (!recordingEnabled) {
            log.info("[Agora] 녹화 비활성(agora.recording.enabled=false) — 시작 생략 lessonId={}", lesson.getId());
            return new RecordingStartResponseDto(lesson.getId(), "", "", channelName);
        }

        // web 모드는 RTC 채널을 구독하지 않으므로 녹화봇 RTC 토큰이 필요 없다.
        String resourceId = acquireResource(channelName);
        String sid = startRecordingInternal(channelName, resourceId, lesson.getId(), orientation);
        lesson.setRecordingInfo(resourceId, sid);

        return new RecordingStartResponseDto(lesson.getId(), resourceId, sid, channelName);
    }

    /**
     * 녹화 중지: Agora stop API만 호출하고 즉시 반환.
     * S3 .m3u8 파일 탐색은 stopRecordingAsync()에서 비동기로 처리.
     * (트랜잭션은 호출자가 관리)
     */
    public RecordingStopResponseDto stopRecording(Lesson lesson) {
        // 녹화 비활성 또는 시작된 녹화가 없으면 무해하게 반환(에러 X).
        if (!recordingEnabled) {
            return new RecordingStopResponseDto(lesson.getId(), "", "disabled");
        }
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
        if (!recordingEnabled) return; // 녹화 비활성 → S3 폴링 자체를 안 함(로컬 에러 도배 방지)
        log.info("[Agora][비동기] S3 폴링 시작 - lessonId={}", lessonId);
        String recordingUrl = findRecordingFromS3(lessonId);
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

        // web 모드(페이지 녹화)는 acquire 시 scene=1 필수
        Map<String, Object> body = Map.of(
                "cname", channelName,
                "uid", "12345",
                "clientRequest", Map.of("scene", 1)
        );

        Map<String, Object> response = post(url, body);
        String resourceId = (String) response.get("resourceId");
        if (resourceId == null) {
            throw BusinessException.internalError("녹화 리소스 획득에 실패했습니다.");
        }
        return resourceId;
    }

    /** 녹화 시작 (web 모드) — SID 반환 */
    private String startRecordingInternal(String channelName, String resourceId, Long lessonId, String orientation) {
        String url = BASE_URL + "/" + agoraConfig.getAppId()
                + "/cloud_recording/resourceid/" + resourceId + "/mode/web/start";

        // 방향 결정 — 화이트보드 종횡비 기반. landscape만 가로, 그 외/null은 세로 폴백.
        // Web Page Recording은 start 시점의 videoWidth/Height가 mp4 해상도로 확정된다(중간 변경 불가).
        boolean landscape = "landscape".equals(orientation);
        int videoWidth = landscape ? 1280 : 720;
        int videoHeight = landscape ? 720 : 1280;

        // 녹화봇이 열 recorder.html 주소 (페이지가 채널의 화이트보드를 실시간 렌더)
        // recorder.html이 프레임 크기를 프론트/녹화 해상도와 일치시키도록 orientation을 함께 전달.
        String recorderUrl = agoraConfig.getRecorderUrlBase()
                + "?channel=" + channelName
                + "&orientation=" + (landscape ? "landscape" : "portrait");

        // 웹 페이지 녹화 서비스 설정
        Map<String, Object> serviceParam = new HashMap<>();
        serviceParam.put("url", recorderUrl);
        serviceParam.put("audioProfile", 0);
        serviceParam.put("videoWidth", videoWidth);   // recorder.html 캔버스와 일치 (portrait 720×1280 / landscape 1280×720)
        serviceParam.put("videoHeight", videoHeight);
        serviceParam.put("maxRecordingHour", 1);

        Map<String, Object> extensionService = new HashMap<>();
        extensionService.put("serviceName", "web_recorder_service");
        extensionService.put("errorHandlePolicy", "error_abort");
        extensionService.put("serviceParam", serviceParam);

        Map<String, Object> extensionServiceConfig = new HashMap<>();
        extensionServiceConfig.put("errorHandlePolicy", "error_abort");
        extensionServiceConfig.put("extensionServices", List.of(extensionService));

        Map<String, Object> recordingFileConfig = new HashMap<>();
        recordingFileConfig.put("avFileType", List.of("hls", "mp4"));

        // S3 저장 설정 (mix 모드와 동일 — 저장 경로 유지)
        Map<String, Object> storageConfig = new HashMap<>();
        storageConfig.put("vendor", 1);                                 // 1=Amazon S3
        storageConfig.put("region", 10);                                // 10=ap-northeast-2 (Seoul)
        storageConfig.put("bucket", bucket);
        storageConfig.put("accessKey", awsAccessKey);
        storageConfig.put("secretKey", awsSecretKey);
        storageConfig.put("fileNamePrefix",
                List.of("lessons", "recordings", String.valueOf(lessonId)));

        Map<String, Object> clientRequest = new HashMap<>();
        clientRequest.put("extensionServiceConfig", extensionServiceConfig);
        clientRequest.put("recordingFileConfig", recordingFileConfig);
        clientRequest.put("storageConfig", storageConfig);

        Map<String, Object> body = new HashMap<>();
        body.put("cname", channelName);
        body.put("uid", "12345");
        body.put("clientRequest", clientRequest);

        log.info("[Agora] startRecording(web) 요청 - cname={}, recorderUrl={}", channelName, recorderUrl);

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
                + "/sid/" + sid + "/mode/web/stop";

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
            // avFileType=["hls","mp4"]라 fileList에 m3u8과 mp4가 섞여 온다.
            // m3u8은 전사·재생 불가이므로 mp4만 고른다.
            // (이 시점에 mp4가 없으면 비워두고, 비동기 60회 폴링 + 5분 스케줄러가 mp4로 채운다)
            for (Map<String, Object> file : fileList) {
                String filename = (String) file.get("filename");
                if (filename != null && filename.endsWith(".mp4")) {
                    recordingUrl = "https://" + bucket + ".s3." + region
                            + ".amazonaws.com/" + filename;
                    break;
                }
            }
        }

        if (recordingUrl.isEmpty()) {
            log.info("[Agora] stop 응답에 fileList 없음 — 비동기 S3 폴링으로 처리 예정, lessonId={}", lessonId);
        }

        log.info("[Agora] stop 응답 - uploadingStatus={}, recordingUrl={}", uploadingStatus, recordingUrl);
        return new String[]{recordingUrl, uploadingStatus};
    }

    /**
     * S3에서 해당 강의의 mp4를 "한 번만" 조회 (sleep 루프 없음).
     * 스케줄러가 주기적으로 호출 → 아직 없으면 null, 생겼으면 S3 URL.
     * stopRecordingAsync의 20분 블로킹이 재시작으로 유실돼도 여기서 복구됨.
     */
    public String resolveRecordingMp4Url(Long lessonId) {
        if (s3Client == null) return null; // local 등 S3 미사용 프로파일
        String prefix = "lessons/recordings/" + lessonId + "/";
        try {
            ListObjectsV2Response res = s3Client.listObjectsV2(
                    ListObjectsV2Request.builder().bucket(bucket).prefix(prefix).build());
            for (S3Object o : res.contents()) {
                if (o.key().endsWith(".mp4")) return toS3Url(o.key());
            }
        } catch (Exception e) {
            log.error("[Agora] mp4 재탐색 실패 - lessonId={}, error={}", lessonId, e.getMessage());
        }
        return null;
    }

    /** S3 ListObjectsV2로 lessons/recordings/{lessonId}/ 경로에서 녹화 파일을 찾아 URL 반환.
     *  web page recording은 ts/m3u8 조각이 먼저 올라오고 mp4(최종 합본)가 나중에 올라온다.
     *  우선순위: mp4 > (mp4를 기다리다 타임아웃 시) m3u8 폴백.
     *  - mp4를 찾으면 즉시 확정.
     *  - m3u8만 있으면 바로 끝내지 않고, 처음 발견 시점부터 추가 M3U8_WAIT_LIMIT회까지
     *    mp4를 더 기다린 뒤 그래도 없으면 m3u8로 폴백.
     *  - 전체 최대 60회, 10초 간격 (≈ 최대 10분). */
    private String findRecordingFromS3(Long lessonId) {
        if (s3Client == null) {
            log.warn("[Agora] S3Client 미주입 상태 (prod 프로파일 아님) — S3 탐색 생략");
            return "";
        }
        String prefix = "lessons/recordings/" + lessonId + "/";
        int maxAttempts = 60;
        String m3u8Fallback = null;   // mp4 끝내 없을 때 쓸 폴백

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                ListObjectsV2Response listResponse = s3Client.listObjectsV2(
                        ListObjectsV2Request.builder()
                                .bucket(bucket)
                                .prefix(prefix)
                                .build()
                );
                String mp4Key = null;
                String m3u8Key = null;
                for (S3Object object : listResponse.contents()) {
                    String key = object.key();
                    if (key.endsWith(".mp4") && mp4Key == null) mp4Key = key;
                    else if (key.endsWith(".m3u8") && m3u8Key == null) m3u8Key = key;
                }

                // ① mp4 발견 → 즉시 확정 (최선)
                if (mp4Key != null) {
                    String resolvedUrl = toS3Url(mp4Key);
                    log.info("[Agora] mp4 발견 → 확정 (시도 {}/{}) - {}", attempt, maxAttempts, resolvedUrl);
                    return resolvedUrl;
                }

                // ② m3u8만 있음 → mp4가 합성될 때까지 계속 기다림
                //    (m3u8/HLS는 Gemini 전사가 불가하므로 절대 폴백으로 확정하지 않는다)
                if (m3u8Key != null) {
                    m3u8Fallback = m3u8Key;
                    log.info("[Agora] m3u8만 있음, mp4 합성 대기 중 (시도 {}/{})", attempt, maxAttempts);
                } else {
                    // ③ 아무것도 없음
                    log.info("[Agora] S3 녹화 파일 없음 (시도 {}/{}) - prefix={}", attempt, maxAttempts, prefix);
                }

                if (attempt < maxAttempts) {
                    Thread.sleep(10000);
                }
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                log.warn("[Agora] S3 폴링 인터럽트 - lessonId={}", lessonId);
                break;
            } catch (Exception e) {
                // 인증/권한 오류(403/401)는 재시도해도 절대 성공하지 않음(잘못된 AWS 키 등)
                // → 60회 도배하지 말고 한 번만 경고하고 중단(녹화 조회 건너뜀).
                if (e instanceof software.amazon.awssdk.awscore.exception.AwsServiceException ase
                        && (ase.statusCode() == 403 || ase.statusCode() == 401)) {
                    log.warn("[Agora] S3 자격증명/권한 오류로 녹화 조회를 중단합니다 — lessonId={}. "
                            + "AWS 키 설정을 확인하세요(로컬은 녹화 미사용일 수 있음).", lessonId);
                    break;
                }
                // 그 외(일시적 오류 등)는 기존대로 재시도 (로그는 warn으로 톤다운)
                log.warn("[Agora] S3 ListObjects 실패 (시도 {}/{}) - prefix={}, error={}",
                        attempt, maxAttempts, prefix, e.getMessage());
                if (attempt < maxAttempts) {
                    try { Thread.sleep(10000); } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            }
        }

        // mp4가 끝내 안 나옴 → m3u8은 전사 불가라 저장하지 않음
        // recording_url을 비워두고 경고만 남긴다 (필요 시 수동 지정/재시도)
        if (m3u8Fallback != null) {
            log.warn("[Agora] mp4 미생성, m3u8만 존재 → recording_url 저장 보류(전사 불가) - lessonId={}, m3u8={}",
                    lessonId, m3u8Fallback);
        }
        log.warn("[Agora] S3 mp4 최종 미발견 - lessonId={}", lessonId);
        return "";
    }

    /** S3 key → 공개 URL */
    private String toS3Url(String key) {
        return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + key;
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
