package com.ieum.backend.domain.auth.oauth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.global.exception.BusinessException;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;

@Component
@EnableConfigurationProperties(NaverOAuthProperties.class)
public class NaverOAuthClient extends AbstractOAuthClient {

    private static final String USER_INFO_URL = "https://openapi.naver.com/v1/nid/me";
    private static final String TOKEN_URL = "https://nid.naver.com/oauth2.0/token";

    private final NaverOAuthProperties properties;

    public NaverOAuthClient(NaverOAuthProperties properties) {
        this.properties = properties;
    }

    @Override
    public AuthProvider provider() {
        return AuthProvider.NAVER;
    }

    @Override
    public OAuthUserInfo getUserInfo(String accessToken) {
        NaverUserResponse res;
        try {
            res = restClient.get()
                    .uri(USER_INFO_URL)
                    .header("Authorization", "Bearer " + accessToken)
                    .retrieve()
                    .body(NaverUserResponse.class);
        } catch (RestClientException e) {
            throw BusinessException.unauthorized("유효하지 않은 네이버 토큰입니다.");
        }
        if (res == null || res.response() == null || res.response().id() == null) {
            throw BusinessException.unauthorized("유효하지 않은 네이버 토큰입니다.");
        }
        NaverUserResponse.Response r = res.response();
        return new OAuthUserInfo(AuthProvider.NAVER, r.id(), r.email(), r.name(), r.profileImage());
    }

    /**
     * 웹 전용 — 네이버는 PKCE 없이 Client Secret으로만 코드 교환을 지원해서
     * (프론트에 시크릿을 둘 수 없으므로) 서버에서 인가코드를 액세스 토큰으로 교환한다.
     */
    public String exchangeCodeForAccessToken(String code, String state) {
        NaverTokenResponse res;
        try {
            res = restClient.get()
                    .uri(TOKEN_URL
                                    + "?grant_type=authorization_code&client_id={clientId}&client_secret={clientSecret}"
                                    + "&code={code}&state={state}",
                            properties.clientId(), properties.clientSecret(), code, state)
                    .retrieve()
                    .body(NaverTokenResponse.class);
        } catch (RestClientException e) {
            throw BusinessException.unauthorized("네이버 인가코드 교환에 실패했습니다.");
        }
        if (res == null || res.accessToken() == null) {
            throw BusinessException.unauthorized("네이버 인가코드 교환에 실패했습니다.");
        }
        return res.accessToken();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record NaverUserResponse(Response response) {
        @JsonIgnoreProperties(ignoreUnknown = true)
        record Response(
                String id,
                String email,
                String name,
                @JsonProperty("profile_image") String profileImage
        ) {
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record NaverTokenResponse(@JsonProperty("access_token") String accessToken) {
    }
}