package com.ieum.backend.global.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "agora")
public class AgoraConfig {
    private String appId;
    private String appCertificate;
    private int tokenExpirySeconds;
    private String customerId;
    private String customerSecret;
}
