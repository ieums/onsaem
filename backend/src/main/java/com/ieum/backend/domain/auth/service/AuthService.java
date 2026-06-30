package com.ieum.backend.domain.auth.service;

import com.ieum.backend.domain.auth.dto.*;
import com.ieum.backend.domain.auth.entity.*;
import com.ieum.backend.domain.auth.entity.EducationStatus;
import com.ieum.backend.domain.auth.jwt.AuthPrincipal;
import com.ieum.backend.domain.auth.oauth.OAuthClientResolver;
import com.ieum.backend.domain.auth.oauth.OAuthUserInfo;
import com.ieum.backend.domain.auth.repository.StudentRepository;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.problem.service.ImageStorageService;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;


@Service
@RequiredArgsConstructor
public class AuthService {

    private final StudentRepository studentRepository;
    private final TutorRepository tutorRepository;
    private final PasswordEncoder passwordEncoder;
    private final OAuthClientResolver oauthClientResolver;
    private final TokenService tokenService;
    private final ImageStorageService imageStorageService;
    private final VerificationDocumentStorage verificationStorage;

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
    public TokenResponse signupTutor(TutorSignupRequest request, MultipartFile document) {   // ← 파라미터 추가
        if (tutorRepository.existsByEmail(request.email())) {
            throw BusinessException.badRequest("이미 가입된 이메일입니다.");
        }
        // 증빙 서류(필수) → S3 업로드 후 URL 확보
        if (document == null || document.isEmpty()) {
            throw BusinessException.badRequest("학력 증빙 서류를 첨부해야 가입할 수 있습니다.");
        }
        String verificationDocumentUrl = verificationStorage.store(document);
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
                .verificationDocumentUrl(verificationDocumentUrl)
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

    /**
     * 소셜 로그인 1단계: 토큰 검증 후 기존 회원이면 바로 로그인
     * 학생/강사 양쪽 테이블을 조회하므로 프론트 토글과 무관하게 자기 역할로 로그인
     * 신규면 계정을 만들지 않고 가입 폼 프리필 정보만 돌려줌
     */
    @Transactional
    public OAuthCheckResponse oauthCheck(String providerName, String token) {
        AuthProvider provider = parseProvider(providerName);
        OAuthUserInfo info = oauthClientResolver.resolve(provider).getUserInfo(token);

        var student = studentRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId());
        if (student.isPresent()) {
            verifyActive(student.get().getStatus());
            return OAuthCheckResponse.loggedIn(
                    tokenService.issue(student.get().getId(), Role.STUDENT));
        }

        var tutor = tutorRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId());
        if (tutor.isPresent()) {
            verifyActive(tutor.get().getStatus());
            return OAuthCheckResponse.loggedIn(
                    tokenService.issue(tutor.get().getId(), Role.TUTOR));
        }

        // 신규 — 가입 안 하고 프리필 정보만
        return OAuthCheckResponse.needsSignup(
                new OAuthProfile(info.email(), info.name(), info.profileImageUrl()));
    }

    /**
     * 소셜 로그인 2단계: 신규 소셜 사용자를 추가 정보와 함께 가입시키고 토큰 발급.
     * 토큰을 재검증해 같은 소셜 신원으로만 가입되게 한다(폼 위변조 방지).
     */
    @Transactional
    public TokenResponse oauthSignup(String providerName, OAuthSignupRequest req, MultipartFile document) {
        AuthProvider provider = parseProvider(providerName);
        Role role = parseRole(req.role());
        OAuthUserInfo info = oauthClientResolver.resolve(provider).getUserInfo(req.token());

        // 이미 가입돼 있으면(양쪽 테이블) 가입 거부 — check 로 로그인해야 함
        boolean exists = studentRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId()).isPresent()
                || tutorRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId()).isPresent();
        if (exists) {
            throw BusinessException.badRequest("이미 가입된 소셜 계정입니다.");
        }

        // 이메일: 소셜이 주면 그 값, 안 주면(카카오 미동의 등) 폼 입력값 사용
        String email = (info.email() != null && !info.email().isBlank())
                ? info.email()
                : req.email();
        if (email == null || email.isBlank()) {
            throw BusinessException.badRequest("이메일을 입력해주세요.");
        }


        return switch (role) {
            case STUDENT -> {
                Student student = studentRepository.save(
                        Student.builder()
                                .provider(info.provider())
                                .providerUserId(info.providerUserId())
                                .email(email)
                                .name(info.name())
                                .profileImageUrl(info.profileImageUrl())
                                .birthDate(req.birthDate())
                                .phone(req.phone())
                                .build());
                yield tokenService.issue(student.getId(), Role.STUDENT);
            }
            case TUTOR -> {
                // 강사 필수값 검증 (로컬 가입과 동일 기준)
                if (req.subjects() == null || req.subjects().isEmpty()) {
                    throw BusinessException.badRequest("과외 가능 과목을 1개 이상 선택해주세요.");
                }
                if (req.educationStatus() == null || req.educationStatus().isBlank()) {
                    throw BusinessException.badRequest("최종학력을 선택해주세요.");
                }
                // 증빙 서류(필수) → S3 업로드
                if (document == null || document.isEmpty()) {
                    throw BusinessException.badRequest("학력 증빙 서류를 첨부해야 가입할 수 있습니다.");
                }
                String verificationDocumentUrl = verificationStorage.store(document);
                Tutor tutor = tutorRepository.save(
                        Tutor.builder()
                                .provider(info.provider())
                                .providerUserId(info.providerUserId())
                                .email(email)
                                .name(info.name())
                                .profileImageUrl(info.profileImageUrl())
                                .birthDate(req.birthDate())
                                .phone(req.phone())
                                .bio(req.bio())
                                .school(req.school())
                                .major(req.major())
                                .experienceYears(req.experienceYears())
                                .educationStatus(EducationStatus.fromLabel(req.educationStatus()))
                                .subjects(req.subjects())
                                .verificationDocumentUrl(verificationDocumentUrl)
                                .build());
                yield tokenService.issue(tutor.getId(), Role.TUTOR);

            }
            default -> throw BusinessException.badRequest("지원하지 않는 가입 역할입니다: " + role);
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
                yield MeResponse.ofTutor(tutor);
            }
            default -> throw BusinessException.forbidden("지원하지 않는 역할입니다.");
        };
    }

    /** 프로필 수정 — 마이페이지. 인증 주체 본인만 수정(보낸 값만 갱신). */
    @Transactional
    public MeResponse updateMe(AuthPrincipal principal, UpdateProfileRequest request) {
        return switch (principal.role()) {
            case STUDENT -> {
                Student student = studentRepository.findById(principal.id())
                        .orElseThrow(() -> BusinessException.notFound("회원을 찾을 수 없습니다."));
                student.updateProfile(request.name(), request.phone(),
                        request.birthDate(), request.profileImageUrl());
                yield MeResponse.of(student, Role.STUDENT);
            }
            case TUTOR -> {
                Tutor tutor = tutorRepository.findById(principal.id())
                        .orElseThrow(() -> BusinessException.notFound("회원을 찾을 수 없습니다."));
                tutor.updateProfile(request.name(), request.phone(),
                        request.birthDate(), request.profileImageUrl());
                if (request.bio() != null || request.school() != null || request.major() != null
                        || request.subjects() != null || request.educationStatus() != null
                        || request.experienceYears() != null) {
                    EducationStatus es = request.educationStatus() != null
                            ? EducationStatus.valueOf(request.educationStatus()) : null;
                    tutor.updateTutorProfile(request.bio(), request.school(), request.major(),
                            request.subjects(), es, request.experienceYears());
                }
                yield MeResponse.ofTutor(tutor);
            }
            default -> throw BusinessException.forbidden("지원하지 않는 역할입니다.");
        };
    }

    /** 프로필 사진 업로드 — 이미지를 저장소에 올리고 그 URL을 프로필에 반영. */
    @Transactional
    public MeResponse updateProfileImage(AuthPrincipal principal, MultipartFile image) {
        if (image == null || image.isEmpty()) {
            throw BusinessException.badRequest("이미지 파일이 필요합니다.");
        }
        String url = imageStorageService.store(image);
        return switch (principal.role()) {
            case STUDENT -> {
                Student student = studentRepository.findById(principal.id())
                        .orElseThrow(() -> BusinessException.notFound("회원을 찾을 수 없습니다."));
                student.updateProfile(null, null, null, url);
                yield MeResponse.of(student, Role.STUDENT);
            }
            case TUTOR -> {
                Tutor tutor = tutorRepository.findById(principal.id())
                        .orElseThrow(() -> BusinessException.notFound("회원을 찾을 수 없습니다."));
                tutor.updateProfile(null, null, null, url);
                yield MeResponse.ofTutor(tutor);
            }
            default -> throw BusinessException.forbidden("지원하지 않는 역할입니다.");
        };
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