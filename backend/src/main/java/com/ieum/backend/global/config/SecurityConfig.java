package com.ieum.backend.global.config;

import com.ieum.backend.domain.auth.jwt.JwtAccessDeniedHandler;
import com.ieum.backend.domain.auth.jwt.JwtAuthenticationEntryPoint;
import com.ieum.backend.domain.auth.jwt.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
    private final JwtAccessDeniedHandler jwtAccessDeniedHandler;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .formLogin(form -> form.disable())
                .httpBasic(basic -> basic.disable())
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/auth/me", "/api/v1/auth/me/**").authenticated()
                        .requestMatchers("/api/v1/ai-tutor/**", "/api/v1/lesson-review/**").hasRole("STUDENT")
                        // JWT 주체 기반 — 결제(학생)·정산(강사)·리뷰/신고(인증)
                        .requestMatchers("/api/v1/payments/**").hasRole("STUDENT")
                        // 관리자/내부 전용 — 강사가 스스로 송금완료/실패/취소·임의 계산을 못 하게 잠금.
                        // (현재 ADMIN 롤이 없으므로 외부 HTTP로는 차단됨. 정산 생성은 스케줄러가 서비스로 직접 호출.)
                        .requestMatchers(
                                "/api/v1/settlements/calculate",
                                "/api/v1/settlements/*/complete",
                                "/api/v1/settlements/*/fail",
                                "/api/v1/settlements/*/cancel",
                                "/api/v1/settlements/*/retry"
                        ).hasRole("ADMIN")
                        .requestMatchers("/api/v1/settlements/**").hasRole("TUTOR")
                        .requestMatchers("/api/v1/reviews/**", "/api/v1/reports/**").authenticated()
                        // 본인 전용(정산 계좌 등록/조회 등) — @AuthenticationPrincipal 의존.
                        // permitAll 그룹의 /tutors/** 보다 먼저 둬야 함(순서 매칭): 토큰 만료/누락 시
                        // NPE 500이 아니라 401을 내보내 FE가 토큰 재발급·재시도하도록 유도.
                        .requestMatchers("/api/v1/tutors/me/**").hasRole("TUTOR")
                        .requestMatchers(
                                "/api/v1/auth/**",
                                "/api/v1/health",
                                "/api/v1/problems/**",
                                "/api/v1/tutors/**",
                                "/api/v1/lesson/token",
                                "/api/v1/lesson/*/images",
                                "/api/v1/lesson/*/start",
                                "/api/v1/lesson/*/extend",
                                "/api/v1/lesson/*/complete",
                                "/api/v1/lesson/*/cancel",
                                "/api/v1/lesson/*/recording/start",
                                "/api/v1/lesson/*/recording/stop",
                                "/ws/**",
                                "/ws-raw",
                                "/api/v1/matching/**",
                                "/uploads/**",
                                "/error",
                                "/recorder.html"
                        ).permitAll()
                        .anyRequest().authenticated()
                )
                .exceptionHandling(e -> e
                        .authenticationEntryPoint(jwtAuthenticationEntryPoint)
                        .accessDeniedHandler(jwtAccessDeniedHandler)
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.addAllowedOriginPattern("*");
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}