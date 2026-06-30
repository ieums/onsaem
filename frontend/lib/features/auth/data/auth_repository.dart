import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/dio_client.dart';
import 'auth_models.dart';
import 'dart:convert';
import 'dart:typed_data';

/// 인증 관련 백엔드 API 호출을 모아둔 곳.
/// (토큰 저장이나 화면 이동은 여기서 안 함 — 순수하게 '서버랑 대화'만)
class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? dioClient;

  // ─── 로컬 로그인 ─────────────────────────────
  Future<AuthTokens> studentLogin({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/student/login',
      data: {'email': email, 'password': password},
    );
    return AuthTokens.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<AuthTokens> tutorLogin({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/tutor/login',
      data: {'email': email, 'password': password},
    );
    return AuthTokens.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // ─── 회원가입 (가입 즉시 토큰 발급됨) ──────────
    Future<AuthTokens> studentSignup({
    required String email,
    required String password,
    required String name,
    required String birthDate, // "yyyy-MM-dd"
    required String phone,
  }) async {
    final res = await _dio.post(
      '/auth/student/signup',
      data: {
        'email': email,
        'password': password,
        'name': name,
        'birthDate': birthDate,
        'phone': phone,
      },
    );
    return AuthTokens.fromJson(res.data['data'] as Map<String, dynamic>);
  }

    Future<AuthTokens> tutorSignup({
    required String email,
    required String password,
    required String name,
    required String birthDate,
    required String phone,
    required String educationStatus,
    required List<String> subjects,
    int? experienceYears,
    String? bio,
    String? school,
    String? major,
    Uint8List? documentBytes,        // ← 추가
    String? documentFileName,        // ← 추가
  }) async {
    final dataJson = jsonEncode({
      'email': email,
      'password': password,
      'name': name,
      'birthDate': birthDate,
      'phone': phone,
      'educationStatus': educationStatus,
      'subjects': subjects,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (bio != null) 'bio': bio,
      if (school != null) 'school': school,
      if (major != null) 'major': major,
    });

    final formData = FormData.fromMap({
      // 백엔드 @RequestPart("data") 가 JSON으로 역직렬화하도록 content-type 지정
      'data': MultipartFile.fromString(
        dataJson,
        contentType: DioMediaType('application', 'json'),
      ),
      if (documentBytes != null && documentFileName != null)
        'document': MultipartFile.fromBytes(
          documentBytes,
          filename: documentFileName,
        ),
    });

    final res = await _dio.post('/auth/tutor/signup', data: formData);
    return AuthTokens.fromJson(res.data['data'] as Map<String, dynamic>);
  }
    // ─── 소셜 로그인 1단계 (check) ────────────────
  Future<OAuthCheckResult> oauthCheck({
    required String provider, // "google" | "kakao" | "naver"
    required String token,
  }) async {
    final res = await _dio.post(
      '/auth/oauth/$provider/check',
      data: {'token': token},
    );
    return OAuthCheckResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // ─── 소셜 로그인 2단계 (signup) ───────────────
  Future<AuthTokens> oauthSignup({
    required String provider,
    required UserRole role,
    required String token,
    required String birthDate,
    required String phone,
    String? email,
    String? educationStatus,
    List<String>? subjects,
    int? experienceYears,
    String? bio,
    String? school,
    String? major,
    Uint8List? documentBytes,        // ← 추가
    String? documentFileName,        // ← 추가
  }) async {
    final dataJson = jsonEncode({
      'role': role.apiValue,
      'token': token,
      'birthDate': birthDate,
      'phone': phone,
      if (email != null) 'email': email,
      if (educationStatus != null) 'educationStatus': educationStatus,
      if (subjects != null) 'subjects': subjects,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (bio != null) 'bio': bio,
      if (school != null) 'school': school,
      if (major != null) 'major': major,
    });

    final formData = FormData.fromMap({
      'data': MultipartFile.fromString(
        dataJson,
        contentType: DioMediaType('application', 'json'),
      ),
      if (documentBytes != null && documentFileName != null)
        'document': MultipartFile.fromBytes(
          documentBytes,
          filename: documentFileName,
        ),
    });

    final res = await _dio.post('/auth/oauth/$provider/signup', data: formData);
    return AuthTokens.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // ─── 비밀번호 재설정 (이메일 인증 코드, LOCAL 계정만) ──
  /// 코드 발송. 서버는 계정 존재 여부와 무관하게 성공을 반환(계정 열거 방지).
  Future<void> requestPasswordReset(String email) async {
    await _dio.post('/auth/password/forgot', data: {'email': email});
  }

  /// 코드 검증 + 새 비밀번호 설정.
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post('/auth/password/reset', data: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  // ─── 내 정보 / 로그아웃 ───────────────────────
  Future<UserProfile> getMe() async {
    final res = await _dio.get('/auth/me');
    return UserProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }
}

/// 앱 어디서든 같은 AuthRepository 를 꺼내 쓸 수 있게 해주는 provider.
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());