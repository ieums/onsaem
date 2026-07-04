package com.ieum.backend.global.config;

import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.auth.jwt.JwtProvider;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessageDeliveryException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * STOMP 인바운드 채널 인증·인가.
 *
 * <p>목적: 실시간 화이트보드(/topic|/app/lesson/{channel}/draw)를 그 수업의 참여자(튜터·학생)와
 * 녹화봇에게만 허용한다. 그 외 목적지(매칭 알림 /topic/tutor|student|matching, /topic/new-problem 등)는
 * <b>손대지 않고 통과</b>시켜 기존 동작을 보존한다.
 *
 * <p>동작:
 * <ul>
 *   <li>CONNECT: STOMP 헤더의 {@code Authorization: Bearer <jwt>} 가 있으면 검증해 Principal 설정.
 *       (없거나 무효면 익명으로 통과 — 토큰 없이 붙는 매칭 STOMP 연결을 깨지 않기 위함.
 *        실제 차단은 화이트보드 SUBSCRIBE/SEND 단계에서 수행한다.)</li>
 *   <li>SUBSCRIBE/SEND: 목적지가 화이트보드일 때만 참여자/녹화봇 인가. 아니면 통과.</li>
 * </ul>
 *
 * <p>성능: 참여자 확인 DB 조회는 (STOMP 세션 × 채널)당 한 번만 하고 세션 속성에 캐시한다.
 * 드로우 SEND가 초당 수십~수백 건이라도 캐시 히트만 발생한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class StompAuthChannelInterceptor implements ChannelInterceptor {

    private static final String BEARER = "Bearer ";
    private static final String TOPIC_PREFIX = "/topic/lesson/";
    private static final String APP_PREFIX = "/app/lesson/";
    private static final String DRAW_SUFFIX = "/draw";
    /** 세션 속성 키 — 이 세션이 참여자로 인가된 채널 집합 */
    private static final String ATTR_AUTHORIZED = "WB_AUTHORIZED_CHANNELS";

    private final JwtProvider jwtProvider;
    private final LessonRepository lessonRepository;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);
        StompCommand command = accessor.getCommand();
        if (command == null) {
            return message; // 하트비트 등 비-STOMP 프레임 — 통과
        }

        switch (command) {
            case CONNECT -> authenticateOnConnect(accessor);
            case SUBSCRIBE, SEND -> authorizeWhiteboard(accessor, command);
            default -> { /* DISCONNECT/ACK/NACK 등 — 통과 */ }
        }
        return message;
    }

    /** CONNECT: 토큰이 있으면 검증해 Principal 부여(없으면 익명 통과). */
    private void authenticateOnConnect(StompHeaderAccessor accessor) {
        String header = accessor.getFirstNativeHeader("Authorization");
        if (header == null || !header.startsWith(BEARER)) {
            return; // 익명 연결 허용 (매칭 STOMP 호환)
        }
        String token = header.substring(BEARER.length());
        try {
            Claims claims = jwtProvider.parse(token);
            if (jwtProvider.isWhiteboardRecorderToken(claims)) {
                // 녹화봇: 특정 채널 읽기 전용
                RecorderPrincipal principal = new RecorderPrincipal(jwtProvider.getSubject(claims));
                accessor.setUser(new UsernamePasswordAuthenticationToken(principal, null, List.of()));
            } else if (jwtProvider.isAccessToken(claims)) {
                AuthPrincipal principal = new AuthPrincipal(jwtProvider.getId(claims), jwtProvider.getRole(claims));
                accessor.setUser(new UsernamePasswordAuthenticationToken(principal, null, principal.authorities()));
            }
            // refresh 토큰 등은 Principal 미설정 → 화이트보드 접근 시 401 성격의 거부로 이어짐
        } catch (JwtException | IllegalArgumentException e) {
            // 위조/만료 토큰 → 익명으로 진행(HTTP JwtAuthenticationFilter와 동일 철학). 화이트보드 단계에서 거부됨.
            log.debug("[STOMP] CONNECT 토큰 검증 실패 — 익명 진행: {}", e.getMessage());
        }
    }

    /** SUBSCRIBE/SEND: 화이트보드 목적지일 때만 인가. */
    private void authorizeWhiteboard(StompHeaderAccessor accessor, StompCommand command) {
        String channelName = whiteboardChannel(accessor.getDestination());
        if (channelName == null) {
            return; // 화이트보드 목적지가 아님(매칭 등) → 통과
        }

        Principal user = accessor.getUser();
        if (!(user instanceof Authentication auth) || auth.getPrincipal() == null) {
            throw reject("화이트보드 접근에는 로그인이 필요합니다.");
        }
        Object principal = auth.getPrincipal();
        boolean isWrite = command == StompCommand.SEND;

        if (principal instanceof RecorderPrincipal recorder) {
            if (isWrite) {
                throw reject("녹화 세션은 화이트보드에 쓸 수 없습니다.");
            }
            if (!recorder.channel().equals(channelName)) {
                throw reject("허용되지 않은 채널입니다.");
            }
            return; // 녹화봇 읽기 허용
        }

        if (principal instanceof AuthPrincipal member) {
            if (isAuthorizedInSession(accessor, channelName)) {
                return; // 캐시 히트 — DB 조회 없이 허용
            }
            Lesson lesson = lessonRepository.findByChannelName(channelName).orElse(null);
            if (lesson == null) {
                throw reject("존재하지 않는 수업입니다.");
            }
            boolean participant = member.id().equals(lesson.getTutorId())
                    || member.id().equals(lesson.getStudentId());
            if (!participant) {
                throw reject("이 수업의 참여자가 아닙니다.");
            }
            rememberAuthorized(accessor, channelName);
            return;
        }

        throw reject("화이트보드 접근 권한이 없습니다.");
    }

    /**
     * 목적지가 화이트보드면 채널명을, 아니면 null을 반환.
     * 구독: /topic/lesson/{channel}/draw · 전송: /app/lesson/{channel}/draw
     */
    private String whiteboardChannel(String destination) {
        if (destination == null) {
            return null;
        }
        String mid;
        if (destination.startsWith(TOPIC_PREFIX)) {
            mid = destination.substring(TOPIC_PREFIX.length());
        } else if (destination.startsWith(APP_PREFIX)) {
            mid = destination.substring(APP_PREFIX.length());
        } else {
            return null;
        }
        if (!mid.endsWith(DRAW_SUFFIX)) {
            return null;
        }
        String channel = mid.substring(0, mid.length() - DRAW_SUFFIX.length());
        return channel.isEmpty() ? null : channel;
    }

    @SuppressWarnings("unchecked")
    private boolean isAuthorizedInSession(StompHeaderAccessor accessor, String channelName) {
        Map<String, Object> attrs = accessor.getSessionAttributes();
        if (attrs == null) {
            return false;
        }
        Set<String> authorized = (Set<String>) attrs.get(ATTR_AUTHORIZED);
        return authorized != null && authorized.contains(channelName);
    }

    @SuppressWarnings("unchecked")
    private void rememberAuthorized(StompHeaderAccessor accessor, String channelName) {
        Map<String, Object> attrs = accessor.getSessionAttributes();
        if (attrs == null) {
            return;
        }
        Set<String> authorized = (Set<String>) attrs.computeIfAbsent(
                ATTR_AUTHORIZED, k -> ConcurrentHashMap.newKeySet());
        authorized.add(channelName);
    }

    private MessageDeliveryException reject(String reason) {
        // STOMP ERROR 프레임으로 클라이언트에 전달되고 해당 프레임은 브로커로 전송되지 않는다.
        return new MessageDeliveryException(reason);
    }

    /** 녹화봇 principal — 인가된 단일 채널을 담는다. */
    private record RecorderPrincipal(String channel) implements Principal {
        @Override
        public String getName() {
            return "recorder:" + channel;
        }
    }
}
