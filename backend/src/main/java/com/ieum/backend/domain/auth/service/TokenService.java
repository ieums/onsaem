package com.ieum.backend.domain.auth.service;

import com.ieum.backend.domain.auth.dto.TokenResponse;
import com.ieum.backend.domain.auth.entity.RefreshToken;
import com.ieum.backend.domain.auth.entity.Role;
import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.auth.jwt.JwtProperties;
import com.ieum.backend.domain.auth.jwt.JwtProvider;
import com.ieum.backend.domain.auth.jwt.TokenHasher;
import com.ieum.backend.domain.auth.repository.RefreshTokenRepository;
import com.ieum.backend.global.exception.BusinessException;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;

/** access/refresh 토큰의 발급·저장·재발급·무효화를 담당. */
@Service
@RequiredArgsConstructor
public class TokenService {

    private final JwtProvider jwtProvider;
    private final JwtProperties jwtProperties;
    private final RefreshTokenRepository refreshTokenRepository;

    /** access + refresh 발급, refresh 는 해시로 저장(있으면 회전) */
    @Transactional
    public TokenResponse issue(Long id, Role role) {
        String accessToken = jwtProvider.createAccessToken(id, role);
        String refreshToken = jwtProvider.createRefreshToken(id, role);
        saveRefreshToken(role, id, refreshToken);
        return new TokenResponse(accessToken, refreshToken, role.name());
    }

    @Transactional
    public TokenResponse reissue(String refreshToken) {
        Claims claims;
        try {
            claims = jwtProvider.parse(refreshToken);
        } catch (JwtException | IllegalArgumentException e) {
            throw BusinessException.unauthorized("유효하지 않은 refresh 토큰입니다.");
        }
        if (jwtProvider.isAccessToken(claims)) {
            throw BusinessException.unauthorized("refresh 토큰이 아닙니다.");
        }
        Long id = jwtProvider.getId(claims);
        Role role = jwtProvider.getRole(claims);

        RefreshToken stored = refreshTokenRepository.findByRoleAndSubjectId(role, id)
                .orElseThrow(() -> BusinessException.unauthorized("로그인이 필요합니다."));
        if (stored.isExpired() || !stored.getToken().equals(TokenHasher.sha256(refreshToken))) {
            throw BusinessException.unauthorized("유효하지 않은 refresh 토큰입니다.");
        }
        return issue(id, role);
    }

    @Transactional
    public void logout(AuthPrincipal principal) {
        if (principal == null) {
            return;
        }
        refreshTokenRepository.deleteByRoleAndSubjectId(principal.role(), principal.id());
    }

    private void saveRefreshToken(Role role, Long subjectId, String refreshToken) {
        String hashed = TokenHasher.sha256(refreshToken);
        LocalDateTime expiresAt = LocalDateTime.now()
                .plus(Duration.ofMillis(jwtProperties.refreshTokenExpiryMs()));
        refreshTokenRepository.findByRoleAndSubjectId(role, subjectId)
                .ifPresentOrElse(
                        existing -> existing.rotate(hashed, expiresAt),
                        () -> refreshTokenRepository.save(RefreshToken.builder()
                                .role(role)
                                .subjectId(subjectId)
                                .token(hashed)
                                .expiresAt(expiresAt)
                                .build()));
    }
}