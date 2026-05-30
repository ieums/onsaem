package com.ieum.backend.domain.lesson.service;

import com.ieum.backend.domain.lesson.dto.LessonImageResponseDto;
import com.ieum.backend.domain.lesson.dto.RecordingStartResponseDto;
import com.ieum.backend.domain.lesson.dto.RecordingStopResponseDto;
import com.ieum.backend.domain.lesson.dto.TokenRequestDto;
import com.ieum.backend.domain.lesson.dto.TokenResponseDto;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.global.agora.AgoraRecordingService;
import com.ieum.backend.global.agora.RtcTokenBuilder2;
import com.ieum.backend.global.config.AgoraConfig;
import com.ieum.backend.global.exception.BusinessException;
import com.ieum.backend.global.s3.S3Service;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class LessonService {

    private final AgoraConfig agoraConfig;
    private final LessonRepository lessonRepository;
    private final S3Service s3Service;
    private final AgoraRecordingService agoraRecordingService;

    @Transactional
    public Lesson createLesson(Long tutorId, Long studentId, String channelName) {
        Lesson lesson = new Lesson(channelName, tutorId, studentId);
        return lessonRepository.save(lesson);
    }

    /**
     * Agora 토큰 발급 (채널이 없으면 자동 생성)
     */
    @Transactional
    public TokenResponseDto generateToken(TokenRequestDto req) {
        Lesson lesson = lessonRepository.findByChannelName(req.getChannelName())
                .orElseGet(() -> lessonRepository.save(new Lesson(req.getChannelName())));

        RtcTokenBuilder2.Role role = "SUBSCRIBER".equalsIgnoreCase(req.getRole())
                ? RtcTokenBuilder2.Role.ROLE_SUBSCRIBER
                : RtcTokenBuilder2.Role.ROLE_PUBLISHER;

        int uid = 0;
        try {
            uid = Integer.parseInt(req.getUid());
        } catch (NumberFormatException ignored) {
        }

        int expireSeconds = agoraConfig.getTokenExpirySeconds();
        String token;
        try {
            token = new RtcTokenBuilder2().buildTokenWithUid(
                    agoraConfig.getAppId(),
                    agoraConfig.getAppCertificate(),
                    req.getChannelName(),
                    uid,
                    role,
                    expireSeconds,
                    expireSeconds
            );
        } catch (Exception e) {
            throw BusinessException.internalError("토큰 생성에 실패했습니다.");
        }

        long expireAt = System.currentTimeMillis() / 1000 + expireSeconds;
        return new TokenResponseDto(lesson.getId(), token, req.getChannelName(), agoraConfig.getAppId(), expireAt);
    }

    /**
     * 수업 중 임시 이미지 S3 업로드
     */
    @Transactional(readOnly = true)
    public LessonImageResponseDto uploadTempImage(Long lessonId, MultipartFile file) {
        findByIdOrThrow(lessonId);
        String imageUrl = s3Service.uploadTempImage(lessonId, file);
        return new LessonImageResponseDto(imageUrl);
    }

    /**
     * 수업 완료: 상태 변경 + 임시 이미지 삭제
     */
    @Transactional
    public void completeLesson(Long lessonId, String recordingUrl) {
        Lesson lesson = findByIdOrThrow(lessonId);
        lesson.complete(recordingUrl);  // recordingUrl null이면 기존 값 유지
        s3Service.deleteTempImages(lessonId);
    }

    /**
     * 녹화 시작: Lesson 상태를 ACTIVE로, Agora Cloud Recording 시작
     */
    @Transactional
    public RecordingStartResponseDto startRecording(Long lessonId) {
        Lesson lesson = findByIdOrThrow(lessonId);
        lesson.start();
        return agoraRecordingService.startRecording(lesson);
    }

    /**
     * 녹화 중지: Agora Cloud Recording 중지 + recordingUrl DB 저장
     */
    @Transactional
    public RecordingStopResponseDto stopRecording(Long lessonId) {
        Lesson lesson = findByIdOrThrow(lessonId);
        return agoraRecordingService.stopRecording(lesson);
    }

    // ──────────── private 헬퍼 ────────────

    private Lesson findByIdOrThrow(Long lessonId) {
        return lessonRepository.findById(lessonId)
                .orElseThrow(() -> BusinessException.notFound("수업을 찾을 수 없습니다."));
    }
}
