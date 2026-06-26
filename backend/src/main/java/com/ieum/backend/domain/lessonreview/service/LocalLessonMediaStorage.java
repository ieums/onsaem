package com.ieum.backend.domain.lessonreview.service;

import com.ieum.backend.global.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Stream;

/**
 * 로컬(local 프로파일) 구현 — AWS 없이 복습 파이프라인을 돌리기 위함.
 *
 * Agora는 로컬 디스크에 녹음을 못 하므로, 음성/영상은 사용자가 수동으로 둔다:
 *   media/recordings/{lessonId}/  아래에 파일(.m4a/.mp4/.mp3/...) 1개를 넣으면 전사·재생된다.
 *   ※ media/ 는 정적 서빙(/uploads/**)에 매핑되지 않는 '비공개' 폴더 →
 *     녹음은 오직 인증+소유권 체크 엔드포인트(recordingPlaybackUrl)로만 접근 가능.
 * 요약 PDF는 uploads/summaries/{lessonId}.pdf (WebConfig가 /uploads/** 로 서빙).
 */
@Slf4j
@Service
@Profile("local")
public class LocalLessonMediaStorage implements LessonMediaStorage {

    private final Path uploadsDir = Paths.get("uploads");   // 정적 서빙(공개) — PDF용
    private final Path mediaDir = Paths.get("media");       // 비공개 — 녹음용
    private static final List<String> AUDIO_EXT =
            List.of(".m4a", ".mp4", ".mp3", ".wav", ".aac", ".ogg", ".webm");

    @Override
    public String defaultRecordingRef(Long lessonId) {
        // 내부 마커(재생 URL이 아님). 실제 파일은 media/recordings/{id}/ 에서 찾는다.
        return "local:recordings/" + lessonId;
    }

    /** media/recordings/{lessonId}/ 에서 재생/전사할 파일 1개를 찾는다. */
    private Path findRecordingFile(Long lessonId) throws IOException {
        Path dir = mediaDir.resolve("recordings").resolve(String.valueOf(lessonId));
        if (!Files.isDirectory(dir)) {
            throw new IOException("로컬 녹음 폴더가 없습니다: " + dir.toAbsolutePath()
                    + " — 이 경로에 녹음/영상 파일을 넣어주세요.");
        }
        // recording.mp4 / recording.mp3 우선, 없으면 첫 음성·영상 파일.
        for (String ext : List.of(".mp4", ".mp3")) {
            Path preferred = dir.resolve("recording" + ext);
            if (Files.isRegularFile(preferred)) return preferred;
        }
        try (Stream<Path> s = Files.list(dir)) {
            Path found = s.filter(Files::isRegularFile)
                    .filter(p -> {
                        String name = p.getFileName().toString().toLowerCase();
                        return AUDIO_EXT.stream().anyMatch(name::endsWith);
                    })
                    .findFirst()
                    .orElse(null);
            if (found == null) {
                throw new IOException("로컬 녹음 파일이 없습니다: " + dir.toAbsolutePath());
            }
            return found;
        }
    }

    @Override
    public Path fetchRecordingToTemp(Long lessonId, String recordingRef) throws IOException {
        Path audio = findRecordingFile(lessonId);
        // 원본 확장자를 유지해야 전사 단계에서 MIME을 올바르게 판별한다(mp3↔mp4 구분).
        String name = audio.getFileName().toString();
        String ext = name.contains(".") ? name.substring(name.lastIndexOf('.')) : ".mp3";
        Path temp = Files.createTempFile("lesson_", ext);
        Files.deleteIfExists(temp);
        Files.copy(audio, temp);
        log.info("[LocalMedia] 강의 {} 녹음 사용: {}", lessonId, audio.toAbsolutePath());
        return temp;
    }

    @Override
    public String recordingPlaybackUrl(Long lessonId, String recordingRef) {
        // 인증+소유권 체크 엔드포인트 경로(프론트가 origin 붙여 절대화 + JWT 헤더로 호출).
        return "/api/v1/lesson-review/lessons/" + lessonId + "/recording";
    }

    @Override
    public Resource openRecordingResource(Long lessonId, String recordingRef) {
        try {
            return new FileSystemResource(findRecordingFile(lessonId));
        } catch (IOException e) {
            throw BusinessException.notFound("녹음 파일을 찾을 수 없습니다: " + e.getMessage());
        }
    }

    @Override
    public String storeSummaryPdf(byte[] pdf, Long lessonId) {
        try {
            Path dir = uploadsDir.resolve("summaries");
            Files.createDirectories(dir);
            Path file = dir.resolve(lessonId + ".pdf");
            Files.write(file, pdf);
            return "/uploads/summaries/" + lessonId + ".pdf"; // WebConfig가 정적 서빙
        } catch (IOException e) {
            throw BusinessException.internalError("요약 PDF 로컬 저장 실패: " + e.getMessage());
        }
    }

    @Override
    public String summaryPdfDownloadUrl(String storedRef) {
        return storedRef; // 이미 /uploads/... 정적 경로
    }
}
