package com.ieum.backend.domain.auth.oauth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.global.exception.BusinessException;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClientException;

@Component
@EnableConfigurationProperties(KakaoOAuthProperties.class)
public class KakaoOAuthClient extends AbstractOAuthClient {

    private static final String USER_INFO_URL = "https://kapi.kakao.com/v2/user/me";
    private static final String TOKEN_URL = "https://kauth.kakao.com/oauth/token";

    private final KakaoOAuthProperties properties;

    public KakaoOAuthClient(KakaoOAuthProperties properties) {
        this.properties = properties;
    }

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

    /**
     * 웹 전용 — 카카오 토큰 엔드포인트가 브라우저發 CORS를 막아놔서,
     * 프론트가 받은 인가코드(PKCE)를 서버에서 대신 액세스 토큰으로 교환한다.
     */
    public String exchangeCodeForAccessToken(String code, String redirectUri, String codeVerifier) {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "authorization_code");
        form.add("client_id", properties.clientId());
        form.add("redirect_uri", redirectUri);
        form.add("code", code);
        form.add("code_verifier", codeVerifier);
        if (properties.clientSecret() != null && !properties.clientSecret().isBlank()) {
            form.add("client_secret", properties.clientSecret());
        }

        KakaoTokenResponse res;
        try {
            res = restClient.post()
                    .uri(TOKEN_URL)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .body(KakaoTokenResponse.class);
        } catch (RestClientException e) {
            throw BusinessException.unauthorized("카카오 인가코드 교환에 실패했습니다.");
        }
        if (res == null || res.accessToken() == null) {
            throw BusinessException.unauthorized("카카오 인가코드 교환에 실패했습니다.");
        }
        return res.accessToken();
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

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record KakaoTokenResponse(@JsonProperty("access_token") String accessToken) {
    }
}