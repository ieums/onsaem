package com.ieum.backend.domain.admin.service;

import com.ieum.backend.domain.admin.entity.Admin;
import com.ieum.backend.domain.admin.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 관리자 계정 조회/추가. 추가는 콘솔 안에서 로그인한 관리자만(공개 가입 아님).
 * 비밀번호는 BCrypt 로 저장하고 username 중복은 거부한다.
 */
@Service
@RequiredArgsConstructor
public class AdminAccountService {

    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<Admin> findAll() {
        return adminRepository.findAll();
    }

    /**
     * 새 관리자 추가. username 중복 또는 빈 입력은 IllegalArgumentException.
     */
    @Transactional
    public Admin create(String username, String rawPassword) {
        String name = username == null ? null : username.trim();
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("아이디를 입력하세요.");
        }
        if (rawPassword == null || rawPassword.isBlank()) {
            throw new IllegalArgumentException("비밀번호를 입력하세요.");
        }
        if (adminRepository.existsByUsername(name)) {
            throw new IllegalArgumentException("이미 존재하는 아이디입니다: " + name);
        }
        return adminRepository.save(new Admin(name, passwordEncoder.encode(rawPassword)));
    }
}
