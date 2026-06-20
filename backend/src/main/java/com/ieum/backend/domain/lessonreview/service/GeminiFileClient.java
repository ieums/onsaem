package com.ieum.backend.domain.lessonreview.service;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.ieum.backend.domain.aitutor.service.GeminiProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.nio.file.Path;
import java.time.Duration;
import java.util.List;

/**
 * Gemini File API 클라이언트.
 * 영상/오디오 파일을 Gemini에 업로드하고 generateContent에 file_uri로 첨부.
 * (채팅용 GeminiClient와 별개 — 큰 파일에 맞춘 RestClient·타임아웃 가짐)
 */
@Slf4j
@Component
@EnableConfigurationProperties(GeminiProperties.class)
public class GeminiFileClient {

    private static final long POLL_INTERVAL_MS = 5000;
    private static final long POLL_TIMEOUT_MS = 10 * 60 * 1000;   // 10분

    private final GeminiProperties properties;
    private final RestClient uploadClient;
    private final RestClient apiClient;

    public GeminiFileClient(GeminiProperties properties) {
        this.properties = properties;

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(15));
        factory.setReadTimeout(Duration.ofMinutes(10));

        this.uploadClient = RestClient.builder()
                .baseUrl("https://generativelanguage.googleapis.com")
                .requestFactory(factory)
                .build();
        this.apiClient = RestClient.builder()
                .baseUrl(properties.baseUrl())
                .requestFactory(factory)
                .build();
    }

    /** 파일 업로드 → ACTIVE 상태 대기 → file URI 반환. */
    public String uploadAndWaitActive(Path file, String mimeType) {
        log.info("[GeminiFile] 업로드 시작: {}", file);
        UploadResponse uploadResp = uploadClient.post()
                .uri("/upload/v1beta/files?uploadType=media")
                .header("x-goog-api-key", properties.api().key())
                .contentType(MediaType.valueOf(mimeType))
                .body(new FileSystemResource(file))
                .retrieve()
                .body(UploadResponse.class);

        if (uploadResp == null || uploadResp.file() == null) {
            throw new RuntimeException("Gemini 업로드 응답이 비어 있음");
        }
        String fileName = uploadResp.file().name();
        String fileUri = uploadResp.file().uri();
        log.info("[GeminiFile] 업로드 완료: name={}, state={}", fileName, uploadResp.file().state());

        // PROCESSING → ACTIVE 폴링
        long deadline = System.currentTimeMillis() + POLL_TIMEOUT_MS;
        String simpleName = fileName.startsWith("files/") ? fileName.substring("files/".length()) : fileName;
        while (System.currentTimeMillis() < deadline) {
            FileMeta meta = apiClient.get()
                    .uri("/files/{name}", simpleName)
                    .header("x-goog-api-key", properties.api().key())
                    .retrieve()
                    .body(FileMeta.class);
            if (meta == null) {
                throw new RuntimeException("파일 상태 조회 응답이 비어 있음");
            }
            log.debug("[GeminiFile] 상태 폴링: {} = {}", fileName, meta.state());
            if ("ACTIVE".equals(meta.state())) {
                log.info("[GeminiFile] ACTIVE 도달: {}", fileName);
                return fileUri;
            }
            if ("FAILED".equals(meta.state())) {
                throw new RuntimeException("Gemini 파일 처리 실패: " + fileName);
            }
            sleep(POLL_INTERVAL_MS);
        }
        throw new RuntimeException("Gemini 파일이 ACTIVE 상태로 전환되지 않음 (타임아웃): " + fileName);
    }

    /** 업로드한 파일로 generateContent 호출 (전사 등). */
    public String generateWithFile(String model, String prompt, String fileUri, String mimeType) {
        var contents = List.of(new Content("user", List.of(
                new Part(null, new FileData(fileUri, mimeType)),
                new Part(prompt, null)
        )));
        var request = new GenerateRequest(contents);

        GenerateResponse resp = apiClient.post()
                .uri("/models/{model}:generateContent", model)
                .header("x-goog-api-key", properties.api().key())
                .contentType(MediaType.APPLICATION_JSON)
                .body(request)
                .retrieve()
                .body(GenerateResponse.class);

        if (resp == null || resp.candidates() == null || resp.candidates().isEmpty()) {
            throw new RuntimeException("Gemini 응답에 candidates 없음");
        }
        var content = resp.candidates().get(0).content();
        if (content == null || content.parts() == null || content.parts().isEmpty()) {
            throw new RuntimeException("Gemini 응답이 비어 있음");
        }
        return content.parts().get(0).text();
    }

    private void sleep(long ms) {
        try { Thread.sleep(ms); }
        catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("대기 중 인터럽트", e);
        }
    }

    // --- Gemini API JSON 매핑 ---

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record UploadResponse(FileMeta file) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record FileMeta(String name, String uri, String state, String mimeType) {}

    private record GenerateRequest(List<Content> contents) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Content(String role, List<Part> parts) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Part(String text, FileData fileData) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    @JsonIgnoreProperties(ignoreUnknown = true)
    private record FileData(String fileUri, String mimeType) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record GenerateResponse(List<Candidate> candidates) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Candidate(Content content) {}
}