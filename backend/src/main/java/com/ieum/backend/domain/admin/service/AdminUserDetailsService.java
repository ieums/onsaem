package com.ieum.backend.domain.admin.service;

import com.ieum.backend.domain.admin.entity.Admin;
import com.ieum.backend.domain.admin.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * /admin 세션 폼 로그인용 UserDetailsService — Admin 테이블 조회(BCrypt).
 * 기존 InMemoryUserDetailsManager 를 대체한다. ROLE_ADMIN 부여.
 */
@Service
@RequiredArgsConstructor
public class AdminUserDetailsService implements UserDetailsService {

    private final AdminRepository adminRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Admin admin = adminRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("관리자 계정을 찾을 수 없습니다: " + username));
        return User.withUsername(admin.getUsername())
                .password(admin.getPasswordHash())
                .roles("ADMIN")
                .build();
    }
}
