package com.ieum.backend.domain.lessonreview.service;

import org.springframework.core.io.Resource;

import java.io.IOException;
import java.nio.file.Path;

/**
 * 복습 미디어(강의 녹음·요약 PDF) 저장 추상화.
 * 이미지의 ImageStorageService(Local/S3)와 같은 프로파일 분기 패턴.
 * - prod : S3 (Agora 녹음 업로드 결과 + PDF S3)
 * - local: 로컬 uploads/ (Agora가 로컬 저장 불가하므로 음성은 수동 드롭)
 */
public interface LessonMediaStorage {

    /**
     * 강의 완료 시 recording_url이 비어 있으면 채울 기본 참조.
     * local: 마커(local:recordings/{id}) 반환 → 스케줄러가 전사 대상으로 인식.
     * prod : null (Agora가 stopRecording에서 실제 S3 URL을 세팅).
     */
    String defaultRecordingRef(Long lessonId);

    /**
     * 전사 가능한 녹음 파일이 실제로 존재하는지(미존재면 전사 스킵, 에러 아님).
     * local: media/recordings/{id}/ 에 파일이 있는지. prod(S3): 항상 true(녹음 URL이 세팅돼 있으면 존재로 간주).
     */
    boolean isRecordingAvailable(Long lessonId, String recordingRef);

    /** 녹음을 전사용 임시 파일로 가져온다. 호출자가 사용 후 삭제 책임. */
    Path fetchRecordingToTemp(Long lessonId, String recordingRef) throws IOException;

    /** 요약 PDF를 저장하고 저장 참조(URL 또는 경로)를 반환한다. */
    String storeSummaryPdf(byte[] pdf, Long lessonId);

    /** 저장된 요약 PDF를 학생에게 줄 다운로드 URL. */
    String summaryPdfDownloadUrl(String storedRef);

    /**
     * 복습 화면에 줄 녹음 '재생 URL'.
     * local: 인증/소유권 체크하는 우리 엔드포인트 경로(/api/v1/lesson-review/lessons/{id}/recording).
     * prod : presigned S3 URL(시간 제한).
     */
    String recordingPlaybackUrl(Long lessonId, String recordingRef);

    /**
     * 녹음 파일을 스트리밍용 Resource로 연다(소유권 체크는 호출 서비스가 이미 수행).
     * local만 사용(파일). prod는 presigned URL로 직접 가므로 호출되지 않음.
     */
    Resource openRecordingResource(Long lessonId, String recordingRef);

    /**
     * 비공개 S3 이미지(문제 이미지 등)를 화면에서 바로 로드 가능한 URL로 변환.
     * prod: presigned URL(시간 제한). local: 상대경로 그대로(정적 서빙).
     */
    String imageDisplayUrl(String rawImageUrl);
}

