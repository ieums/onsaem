package com.ieum.backend.domain.auth.jwt;

import com.ieum.backend.domain.auth.entity.Role;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.Collection;
import java.util.List;

/**
 * 인증된 요청 주체. 컨트롤러에서 @AuthenticationPrincipal AuthPrincipal 로 꺼내 사용
 * id 는 student.id 또는 tutor.id (role 로 어느 테이블인지 구분)
 */
public record AuthPrincipal(Long id, Role role) {

    public Collection<? extends GrantedAuthority> authorities() {
        return List.of(new SimpleGrantedAuthority(role.authority()));
    }
}