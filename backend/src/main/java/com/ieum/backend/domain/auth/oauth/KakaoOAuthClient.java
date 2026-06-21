package com.ieum.backend.domain.auth.oauth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.global.exception.BusinessException;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;

@Component
public class KakaoOAuthClient extends AbstractOAuthClient {

    private static final String USER_INFO_URL = "https://kapi.kakao.com/v2/user/me";

    @Override
    public AuthProvider provider() {
        return AuthProvider.KAKAO;
    }

    @Override
    public OAuthUserInfo getUserInfo(String accessToken) {
        KakaoUserResponse res;
        try {
            res = restClient.get()
                    .uri(USER_INFO_URL)
                    .header("Authorization", "Bearer " + accessToken)
                    .retrieve()
                    .body(KakaoUserResponse.class);
        } catch (RestClientException e) {
            throw BusinessException.unauthorized("유효하지 않은 카카오 토큰입니다.");
        }
        if (res == null || res.id() == null) {
            throw BusinessException.unauthorized("유효하지 않은 카카오 토큰입니다.");
        }

        String email = null;
        String nickname = null;
        String profileImage = null;
        if (res.kakaoAccount() != null) {
            email = res.kakaoAccount().email();
            if (res.kakaoAccount().profile() != null) {
                nickname = res.kakaoAccount().profile().nickname();
                profileImage = res.kakaoAccount().profile().profileImageUrl();
            }
        }
        return new OAuthUserInfo(AuthProvider.KAKAO, String.valueOf(res.id()), email, nickname, profileImage);
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record KakaoUserResponse(
            Long id,
            @JsonProperty("kakao_account") KakaoAccount kakaoAccount
    ) {
        @JsonIgnoreProperties(ignoreUnknown = true)
        record KakaoAccount(String email, Profile profile) {
            @JsonIgnoreProperties(ignoreUnknown = true)
            record Profile(
                    String nickname,
                    @JsonProperty("profile_image_url") String profileImageUrl
            ) {
            }
        }
    }
}