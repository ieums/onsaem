import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/dio_client.dart';
import 'auth_models.dart';

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
  }) async {
    final res = await _dio.post(
      '/auth/student/signup',
      data: {'email': email, 'password': password, 'name': name},
    );
    return AuthTokens.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<AuthTokens> tutorSignup({
    required String email,
    required String password,
    required String name,
    String? bio,
    String? school,
    String? major,
  }) async {
    final res = await _dio.post(
      '/auth/tutor/signup',
      data: {
        'email': email,
        'password': password,
        'name': name,
        if (bio != null) 'bio': bio,
        if (school != null) 'school': school,
        if (major != null) 'major': major,
      },
    );
    return AuthTokens.fromJson(res.data['data'] as Map<String, dynamic>);
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