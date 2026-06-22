package com.ieum.backend.domain.lessonreview.service;

import com.ieum.backend.domain.aitutor.entity.AiTutorMessage;
import com.ieum.backend.domain.aitutor.entity.AiTutorMessageRole;
import com.ieum.backend.domain.aitutor.service.GeminiClient;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscript;
import com.ieum.backend.domain.lessonreview.entity.LessonTranscriptStatus;
import com.ieum.backend.domain.lessonreview.repository.LessonQueryRepository;
import com.ieum.backend.domain.lessonreview.repository.LessonTranscriptRepository;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import com.vladsch.flexmark.html.HtmlRenderer;
import com.vladsch.flexmark.parser.Parser;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;

import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.time.Duration;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.List;
import com.ieum.backend.global.util.ClasspathLoader;


/**
 * 강의 영상 트랜스크립트 → 학습 자료 PDF 생성 + S3 업로드.
 * Scheduler가 PDF 처리 대상 강의를 발견하면 lessonId 단위로 호출.
 * 학생이 다운로드 요청 시에는 generatePresignedUrl()로 1시간 유효 URL 발급.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LessonSummaryService {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private static final String SUMMARY_SYSTEM_PROMPT = ClasspathLoader.loadAsString("prompts/lesson-summary.md");
    private static final String HTML_TEMPLATE = ClasspathLoader.loadAsString("templates/lesson-summary.html");

    @Value("${cloud.aws.s3.bucket:onsaem-bucket}")
    private String bucket;

    @Value("${cloud.aws.region.static:ap-northeast-2}")
    private String region;

    @Value("${spring.cloud.aws.credentials.access-key}")
    private String accessKey;

    @Value("${spring.cloud.aws.credentials.secret-key}")
    private String secretKey;

    private final LessonQueryRepository lessonQueryRepository;
    private final LessonTranscriptRepository lessonTranscriptRepository;
    private final GeminiClient geminiClient;
    private final S3Client s3Client;

    /**
     * 한 강의의 PDF 학습 자료를 생성해 S3에 업로드하고 DB에 URL 저장.
     * Scheduler가 호출.
     */
    @Transactional
    public void generateAndUpload(Long lessonId) {
        log.info("[SummaryPDF] 강의 {} 처리 시작", lessonId);

        LessonInfo lesson = lessonQueryRepository.findById(lessonId).orElse(null);
        if (lesson == null) {
            log.warn("[SummaryPDF] 강의 {} — lessons 에 없음. 건너뜀.", lessonId);
            return;
        }
        if (lesson.problemId() == null) {
            log.warn("[SummaryPDF] 강의 {} — problem_id 없음. 데이터 채워질 때까지 대기.", lessonId);
            return;
        }

        LessonTranscript transcript = lessonTranscriptRepository.findByLessonId(lessonId).orElse(null);
        if (transcript == null || transcript.getStatus() != LessonTranscriptStatus.COMPLETED) {
            log.warn("[SummaryPDF] 강의 {} — 전사 미완료. 건너뜀.", lessonId);
            return;
        }

        List<String> imageUrls = lessonQueryRepository.findProblemImageUrlsByLessonId(lessonId);
        if (imageUrls.isEmpty()) {
            log.warn("[SummaryPDF] 강의 {} — 문제 이미지 없음. 건너뜀.", lessonId);
            return;
        }

        transcript.markPdfProcessing();

        try {
            // 1) Gemini로 마크다운 요약 생성
            String markdown = generateMarkdownSummary(transcript.getTranscript());
            log.info("[SummaryPDF] 강의 {} 마크다운 요약 생성 (length={})", lessonId, markdown.length());

            // 2) 마크다운 → HTML (이미지 base64 임베드 포함)
            String html = buildHtml(lesson, markdown, imageUrls);

            // 3) HTML → PDF 바이트
            byte[] pdfBytes = htmlToPdf(html);
            log.info("[SummaryPDF] 강의 {} PDF 생성 완료 (size={} bytes)", lessonId, pdfBytes.length);

            // 4) S3 업로드
            String s3Url = uploadToS3(pdfBytes, lessonId);
            log.info("[SummaryPDF] 강의 {} S3 업로드 완료: {}", lessonId, s3Url);

            // 5) DB 상태/URL 저장
            transcript.markPdfCompleted(s3Url);

        } catch (Exception e) {
            log.error("[SummaryPDF] 강의 {} PDF 생성 실패", lessonId, e);
            transcript.markPdfFailed(e.getMessage());
            // throw 안 함 — 트랜잭션 커밋해서 FAILED 영속화. 다음 폴링에서 재시도.
        }
    }

    /**
     * 캐시된 S3 URL을 학생에게 줄 presigned URL(1시간 유효)로 변환.
     * 학생이 다운로드 엔드포인트 호출 시 사용.
     */
    public String generatePresignedUrl(String s3Url) {
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

    // ─── 내부 헬퍼 ─────────────────────────────────────

    private String generateMarkdownSummary(String transcript) {
        AiTutorMessage prompt = AiTutorMessage.builder()
                .role(AiTutorMessageRole.USER)
                .content("아래 강의 전사 내용입니다:\n\n" + transcript
                        + "\n\n위 내용을 학습 노트(마크다운)로 정리해 주세요.")
                .build();
        return geminiClient.generate(SUMMARY_SYSTEM_PROMPT, List.of(prompt));
    }

    private String buildHtml(LessonInfo lesson, String markdown, List<String> imageUrls) {
        // 1) 마크다운 → HTML 본문
        Parser parser = Parser.builder().build();
        HtmlRenderer renderer = HtmlRenderer.builder().build();
        String summaryHtml = renderer.render(parser.parse(markdown));

        // 2) 이미지를 base64 data URI 로 임베드
        StringBuilder imagesHtml = new StringBuilder();
        for (int i = 0; i < imageUrls.size(); i++) {
            String dataUri = fetchAsDataUri(imageUrls.get(i));
            if (dataUri != null) {
                imagesHtml.append(String.format(
                        "<div class=\"problem-image\"><img src=\"%s\" /><div class=\"caption\">문제 이미지 %d</div></div>",
                        dataUri, i + 1));
            }
        }

        String startedAt = lesson.startedAt() != null ? lesson.startedAt().format(FMT) : "";
        String endedAt = lesson.endedAt() != null ? lesson.endedAt().format(FMT) : "";

        // 3) HTML 템플릿의 placeholder 치환
        return HTML_TEMPLATE
                .replace("{{startedAt}}", startedAt)
                .replace("{{endedAt}}", endedAt)
                .replace("{{images}}", imagesHtml.toString())
                .replace("{{summary}}", summaryHtml);
    }

    private String fetchAsDataUri(String imageUrl) {
        try {
            byte[] bytes;
            try (var in = new java.net.URL(imageUrl).openStream()) {
                bytes = in.readAllBytes();
            }
            String lower = imageUrl.toLowerCase();
            String mime = lower.endsWith(".png") ? "image/png"
                    : lower.endsWith(".webp") ? "image/webp"
                    : "image/jpeg";
            return "data:" + mime + ";base64," + Base64.getEncoder().encodeToString(bytes);
        } catch (Exception e) {
            log.warn("[SummaryPDF] 이미지 가져오기 실패: {}", imageUrl, e);
            return null;
        }
    }

    private byte[] htmlToPdf(String html) throws Exception {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            builder.useFont(
                    () -> getClass().getResourceAsStream("/fonts/NotoSansKR-Regular.ttf"),
                    "NotoSansKR");
            builder.withHtmlContent(html, getClass().getResource("/").toString());
            builder.toStream(out);
            builder.run();
            return out.toByteArray();
        }
    }

    private String uploadToS3(byte[] pdfBytes, Long lessonId) {
        String key = "lessons/summaries/" + lessonId + "/summary.pdf";
        s3Client.putObject(
                PutObjectRequest.builder()
                        .bucket(bucket)
                        .key(key)
                        .contentType("application/pdf")
                        .build(),
                RequestBody.fromBytes(pdfBytes)
        );
        return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + key;
    }

    private String extractS3Key(String s3Url) {
        URI uri = URI.create(s3Url);
        String path = uri.getPath();
        return path.startsWith("/") ? path.substring(1) : path;
    }

}