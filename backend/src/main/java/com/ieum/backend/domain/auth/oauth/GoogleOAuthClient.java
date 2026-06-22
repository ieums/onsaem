package com.ieum.backend.domain.auth.oauth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.global.exception.BusinessException;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;

@Component
@EnableConfigurationProperties(GoogleOAuthProperties.class)
public class GoogleOAuthClient extends AbstractOAuthClient {

    private static final String TOKEN_INFO_URL = "https://oauth2.googleapis.com/tokeninfo";

    private final GoogleOAuthProperties properties;

    public GoogleOAuthClient(GoogleOAuthProperties properties) {
        this.properties = properties;
    }

    @Override
    public AuthProvider provider() {
        return AuthProvider.GOOGLE;
    }

    @Override
    public OAuthUserInfo getUserInfo(String idToken) {
        GoogleTokenInfo info;
        try {
            info = restClient.get()
                    .uri(TOKEN_INFO_URL + "?id_token={token}", idToken)
                    .retrieve()
                    .body(GoogleTokenInfo.class);
        } catch (RestClientException e) {
            throw BusinessException.unauthorized("유효하지 않은 구글 토큰입니다.");
        }
        if (info == null || info.sub() == null) {
            throw BusinessException.unauthorized("유효하지 않은 구글 토큰입니다.");
        }
        if (!properties.clientId().equals(info.aud())) {
            throw BusinessException.unauthorized("이 앱을 위한 구글 토큰이 아닙니다.");
        }
        return new OAuthUserInfo(
                AuthProvider.GOOGLE, info.sub(), info.email(), info.name(), info.picture());
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record GoogleTokenInfo(String sub, String email, String name, String picture, String aud) {
    }
}