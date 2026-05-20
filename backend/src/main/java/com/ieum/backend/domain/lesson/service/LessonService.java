package com.ieum.backend.domain.lesson.service;

import com.ieum.backend.domain.lesson.dto.LessonImageResponseDto;
import com.ieum.backend.domain.lesson.dto.TokenRequestDto;
import com.ieum.backend.domain.lesson.dto.TokenResponseDto;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
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

    @Transactional
    public TokenResponseDto generateToken(TokenRequestDto req) {
        lessonRepository.findByChannelName(req.getChannelName())
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
        return new TokenResponseDto(token, req.getChannelName(), agoraConfig.getAppId(), expireAt);
    }

    /**
     * 수업 중 임시 이미지 업로드
     */
    @Transactional(readOnly = true)
    public LessonImageResponseDto uploadTempImage(Long lessonId, MultipartFile file) {
        lessonRepository.findById(lessonId)
                .orElseThrow(() -> BusinessException.notFound("수업을 찾을 수 없습니다."));
        String imageUrl = s3Service.uploadTempImage(lessonId, file);
        return new LessonImageResponseDto(imageUrl);
    }

    /**
     * 수업 완료: 엔티티 상태 변경 + 임시 이미지 전체 삭제
     */
    @Transactional
    public void completeLesson(Long lessonId, String recordingUrl) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> BusinessException.notFound("수업을 찾을 수 없습니다."));
        lesson.complete(recordingUrl);
        s3Service.deleteTempImages(lessonId);
    }
}
