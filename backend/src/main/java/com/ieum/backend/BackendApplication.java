package com.ieum.backend;

import com.ieum.backend.global.config.AgoraConfig;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.util.TimeZone;

@SpringBootApplication
@EnableScheduling
@EnableAsync
@EnableConfigurationProperties(AgoraConfig.class)
public class BackendApplication {

    public static void main(String[] args) {
        // 서버 OS가 UTC(EC2 등)여도 모든 LocalDateTime.now()가 KST로 찍히도록 고정.
        // (안 하면 prod에서 createdAt이 UTC로 저장돼 KST 기기에 '9시간 전'으로 보임)
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Seoul"));
        SpringApplication.run(BackendApplication.class, args);
    }

}
