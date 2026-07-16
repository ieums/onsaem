package com.ieum.backend.domain.auth.jwt;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/** application.yml 의 jwt.* 바인딩. expiry 는 밀리초. */
@ConfigurationProperties(prefix = "jwt")
public record JwtProperties(
        String secret,
        @DefaultValue("3600000") long accessTokenExpiryMs,
        @DefaultValue("1209600000") long refreshTokenExpiryMs
) {
}