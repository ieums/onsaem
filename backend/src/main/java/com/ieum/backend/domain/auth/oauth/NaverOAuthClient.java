package com.ieum.backend.domain.auth.oauth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.global.exception.BusinessException;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;

@Component
public class NaverOAuthClient extends AbstractOAuthClient {

    private static final String USER_INFO_URL = "https://openapi.naver.com/v1/nid/me";

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
}