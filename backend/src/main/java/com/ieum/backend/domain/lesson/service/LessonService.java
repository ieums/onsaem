package com.ieum.backend.domain.lesson.service;

import com.ieum.backend.domain.lesson.dto.TokenRequestDto;
import com.ieum.backend.domain.lesson.dto.TokenResponseDto;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.global.agora.RtcTokenBuilder2;
import com.ieum.backend.global.config.AgoraConfig;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LessonService {

    private final AgoraConfig agoraConfig;
    private final LessonRepository lessonRepository;

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
}
