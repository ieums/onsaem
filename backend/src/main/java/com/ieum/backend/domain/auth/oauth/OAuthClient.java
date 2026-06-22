package com.ieum.backend.domain.auth.oauth;

import com.ieum.backend.domain.auth.entity.AuthProvider;

/** provider별 소셜 토큰 검증 + 사용자정보 조회. 구현체가 자신이 담당하는 provider 를 선언 */
public interface OAuthClient {

    AuthProvider provider();

    /** 프론트가 넘긴 토큰(idToken/accessToken)을 검증하고 사용자정보를 추출 */
    OAuthUserInfo getUserInfo(String token);
}