package com.ieum.backend.domain.auth.service;

import com.ieum.backend.domain.auth.dto.LoginRequest;
import com.ieum.backend.domain.auth.dto.MeResponse;
import com.ieum.backend.domain.auth.dto.StudentSignupRequest;
import com.ieum.backend.domain.auth.dto.TokenResponse;
import com.ieum.backend.domain.auth.dto.TutorSignupRequest;
import com.ieum.backend.domain.auth.entity.*;
import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.auth.oauth.OAuthClientResolver;
import com.ieum.backend.domain.auth.oauth.OAuthUserInfo;
import com.ieum.backend.domain.auth.repository.StudentRepository;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final StudentRepository studentRepository;
    private final TutorRepository tutorRepository;
    private final PasswordEncoder passwordEncoder;
    private final OAuthClientResolver oauthClientResolver;
    private final TokenService tokenService;

    @Transactional
    public TokenResponse signupStudent(StudentSignupRequest request) {
        if (studentRepository.existsByEmail(request.email())) {
            throw BusinessException.badRequest("이미 가입된 이메일입니다.");
        }
        Student student = Student.builder()
                .email(request.email())
                .password(passwordEncoder.encode(request.password()))
                .name(request.name())
                .birthDate(request.birthDate())
                .phone(request.phone())
                .provider(AuthProvider.LOCAL)
                .build();
        studentRepository.save(student);
        return tokenService.issue(student.getId(), Role.STUDENT);
    }

    @Transactional
    public TokenResponse signupTutor(TutorSignupRequest request) {
        if (tutorRepository.existsByEmail(request.email())) {
            throw BusinessException.badRequest("이미 가입된 이메일입니다.");
        }
        Tutor tutor = Tutor.builder()
                .email(request.email())
                .password(passwordEncoder.encode(request.password()))
                .name(request.name())
                .birthDate(request.birthDate())
                .phone(request.phone())
                .provider(AuthProvider.LOCAL)
                .bio(request.bio())
                .school(request.school())
                .major(request.major())
                .experienceYears(request.experienceYears())
                .educationStatus(EducationStatus.fromLabel(request.educationStatus()))
                .subjects(request.subjects())
                .build();
        tutorRepository.save(tutor);
        return tokenService.issue(tutor.getId(), Role.TUTOR);
    }

    @Transactional
    public TokenResponse loginStudent(LoginRequest request) {
        Student student = studentRepository.findByEmail(request.email())
                .orElseThrow(() -> BusinessException.unauthorized("이메일 또는 비밀번호가 올바르지 않습니다."));
        verifyPassword(request.password(), student.getPassword());
        verifyActive(student.getStatus());
        return tokenService.issue(student.getId(), Role.STUDENT);
    }

    @Transactional
    public TokenResponse loginTutor(LoginRequest request) {
        Tutor tutor = tutorRepository.findByEmail(request.email())
                .orElseThrow(() -> BusinessException.unauthorized("이메일 또는 비밀번호가 올바르지 않습니다."));
        verifyPassword(request.password(), tutor.getPassword());
        verifyActive(tutor.getStatus());
        return tokenService.issue(tutor.getId(), Role.TUTOR);
    }

    @Transactional
    public TokenResponse oauthLogin(String providerName, String roleName, String token) {
        AuthProvider provider = parseProvider(providerName);
        Role role = parseRole(roleName);
        OAuthUserInfo info = oauthClientResolver.resolve(provider).getUserInfo(token);
        return switch (role) {
            case STUDENT -> oauthLoginStudent(info);
            case TUTOR -> oauthLoginTutor(info);
        };
    }

    @Transactional(readOnly = true)
    public MeResponse getMe(AuthPrincipal principal) {
        return switch (principal.role()) {
            case STUDENT -> {
                Student student = studentRepository.findById(principal.id())
                        .orElseThrow(() -> BusinessException.notFound("회원을 찾을 수 없습니다."));
                yield MeResponse.of(student, Role.STUDENT);
            }
            case TUTOR -> {
                Tutor tutor = tutorRepository.findById(principal.id())
                        .orElseThrow(() -> BusinessException.notFound("회원을 찾을 수 없습니다."));
                yield MeResponse.of(tutor, Role.TUTOR);
            }
        };
    }

    private TokenResponse oauthLoginStudent(OAuthUserInfo info) {
        Student student = studentRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId())
                .orElseGet(() -> {
                    // 같은 소셜 계정이 이미 강사로 가입돼 있으면 차단 (한 계정 = 한 역할)
                    if (tutorRepository
                            .findByProviderAndProviderUserId(info.provider(), info.providerUserId())
                            .isPresent()) {
                        throw BusinessException.badRequest("이미 강사로 가입된 소셜 계정입니다.");
                    }
                    return studentRepository.save(
                            Student.builder()
                                    .provider(info.provider())
                                    .providerUserId(info.providerUserId())
                                    .email(info.email())
                                    .name(info.name())
                                    .profileImageUrl(info.profileImageUrl())
                                    .build());
                });
        verifyActive(student.getStatus());
        return tokenService.issue(student.getId(), Role.STUDENT);
    }
    private TokenResponse oauthLoginTutor(OAuthUserInfo info) {
        Tutor tutor = tutorRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId())
                .orElseGet(() -> {
                    // 같은 소셜 계정이 이미 학생으로 가입돼 있으면 차단 (한 계정 = 한 역할)
                    if (studentRepository
                            .findByProviderAndProviderUserId(info.provider(), info.providerUserId())
                            .isPresent()) {
                        throw BusinessException.badRequest("이미 학생으로 가입된 소셜 계정입니다.");
                    }
                    return tutorRepository.save(
                            Tutor.builder()
                                    .provider(info.provider())
                                    .providerUserId(info.providerUserId())
                                    .email(info.email())
                                    .name(info.name())
                                    .profileImageUrl(info.profileImageUrl())
                                    .build());
                });
        verifyActive(tutor.getStatus());
        return tokenService.issue(tutor.getId(), Role.TUTOR);
    }

    private void verifyPassword(String raw, String encoded) {
        if (encoded == null || !passwordEncoder.matches(raw, encoded)) {
            throw BusinessException.unauthorized("이메일 또는 비밀번호가 올바르지 않습니다.");
        }
    }

    private void verifyActive(AccountStatus status) {
        if (status == AccountStatus.SUSPENDED) {
            throw BusinessException.unauthorized("정지된 계정입니다.");
        }
    }

    private AuthProvider parseProvider(String providerName) {
        try {
            AuthProvider provider = AuthProvider.valueOf(providerName.toUpperCase());
            if (provider == AuthProvider.LOCAL) {
                throw new IllegalArgumentException();
            }
            return provider;
        } catch (IllegalArgumentException e) {
            throw BusinessException.badRequest("지원하지 않는 소셜 로그인입니다: " + providerName);
        }
    }

    private Role parseRole(String roleName) {
        try {
            return Role.valueOf(roleName.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw BusinessException.badRequest("role 은 student 또는 tutor 여야 합니다.");
        }
    }
}