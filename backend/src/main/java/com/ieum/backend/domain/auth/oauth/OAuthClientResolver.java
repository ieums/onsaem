package com.ieum.backend.domain.auth.oauth;

import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.global.exception.BusinessException;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class OAuthClientResolver {

    private final Map<AuthProvider, OAuthClient> clients;

    public OAuthClientResolver(List<OAuthClient> clientList) {
        this.clients = clientList.stream()
                .collect(Collectors.toMap(OAuthClient::provider, Function.identity()));
    }

    public OAuthClient resolve(AuthProvider provider) {
        OAuthClient client = clients.get(provider);
        if (client == null) {
            throw BusinessException.badRequest("지원하지 않는 소셜 로그인입니다: " + provider);
        }
        return client;
    }
}