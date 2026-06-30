package com.ieum.backend.domain.admin;

import com.ieum.backend.domain.admin.entity.Admin;
import com.ieum.backend.domain.admin.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * 앱 기동 시 Admin 테이블이 비었으면 application.yml 의 env 계정(admin.username/password)을
 * BCrypt 로 시드한다. 기존 env 기반 로그인이 DB 전환 후에도 깨지지 않도록 보장.
 * 이미 계정이 있으면 아무것도 하지 않는다(운영 중 비번 덮어쓰기 방지).
 */
@Component
@RequiredArgsConstructor
public class AdminAccountSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminAccountSeeder.class);

    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${admin.username:admin}")
    private String adminUsername;

    @Value("${admin.password:admin1234}")
    private String adminPassword;

    @Override
    public void run(ApplicationArguments args) {
        if (adminRepository.count() > 0) {
            return;
        }
        adminRepository.save(new Admin(adminUsername, passwordEncoder.encode(adminPassword)));
        log.info("[AdminAccountSeeder] 초기 관리자 계정 시드 완료: username={}", adminUsername);
    }
}
