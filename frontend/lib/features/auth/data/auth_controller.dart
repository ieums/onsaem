import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/storage/token_storage.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

/// 로그인/회원가입/로그아웃의 '흐름'을 조율
/// (서버 호출은 AuthRepository, 토큰 저장은 tokenStorage 에 위임하고
///  여기서는 그 순서를 엮고 로그인 상태를 갱신만)
class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  // ─── 로그인 ───────────────────────────────
  Future<void> studentLogin({
    required String email,
    required String password,
  }) async {
    final tokens = await _repo.studentLogin(email: email, password: password);
    await _onAuthenticated(tokens);
  }

  Future<void> tutorLogin({
    required String email,
    required String password,
  }) async {
    final tokens = await _repo.tutorLogin(email: email, password: password);
    await _onAuthenticated(tokens);
  }

  // ─── 회원가입 (가입 즉시 로그인됨) ───────────
    Future<void> studentSignup({
    required String email,
    required String password,
    required String name,
    required String birthDate,
    required String phone,
  }) async {
    final tokens = await _repo.studentSignup(
      email: email,
      password: password,
      name: name,
      birthDate: birthDate,
      phone: phone,
    );
    await _onAuthenticated(tokens);
  }

    Future<void> tutorSignup({
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
  }) async {
    final tokens = await _repo.tutorSignup(
      email: email,
      password: password,
      name: name,
      birthDate: birthDate,
      phone: phone,
      educationStatus: educationStatus,
      subjects: subjects,
      experienceYears: experienceYears,
      bio: bio,
      school: school,
      major: major,
    );
    await _onAuthenticated(tokens);
  }
    // ─── 소셜 로그인 1단계 ────────────────────────
  /// 기존 회원이면 즉시 로그인 처리하고 결과 반환.
  /// 신규면 로그인하지 않고 결과(profile)만 반환 → 화면이 가입 폼으로 이동.
  Future<OAuthCheckResult> oauthCheck({
    required String provider,
    required String token,
  }) async {
    final result = await _repo.oauthCheck(provider: provider, token: token);
    if (result.registered && result.tokens != null) {
      await _onAuthenticated(result.tokens!);
    }
    return result;
  }

  // ─── 소셜 로그인 2단계 ────────────────────────
  /// 신규 소셜 사용자 가입 + 즉시 로그인.
  Future<void> oauthSignup({
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
  }) async {
    final tokens = await _repo.oauthSignup(
      provider: provider,
      role: role,
      token: token,
      birthDate: birthDate,
      phone: phone,
      email: email,
      educationStatus: educationStatus,
      subjects: subjects,
      experienceYears: experienceYears,
      bio: bio,
      school: school,
      major: major,
    );
    await _onAuthenticated(tokens);
  }

  // ─── 앱 시작 시 세션 복원 ─────────────────────
  /// 저장된 토큰이 있으면 me 를 불러 로그인 상태를 되살린다.
  Future<void> restoreSession() async {
    final token = await tokenStorage.readAccessToken();
    if (token == null) return; // 비로그인 상태
    try {
      await _loadCurrentUser();
    } catch (_) {
      await tokenStorage.clear(); // 토큰이 더 이상 유효하지 않음
    }
  }

  // ─── 로그아웃 ─────────────────────────────
  Future<void> logout() async {
    try {
      await _repo.logout(); // 서버 통보 (실패해도 로컬은 정리)
    } catch (_) {}
    await tokenStorage.clear();
    _ref.read(currentUserProvider.notifier).state = null;
  }

  // ─── 내부 공통 처리 ───────────────────────
  /// 토큰 저장 → me 조회 → 로그인 상태 갱신
  Future<void> _onAuthenticated(AuthTokens tokens) async {
    await tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final me = await _repo.getMe();
    _ref.read(currentUserProvider.notifier).state = UserSession(
      id: me.id,
      isTutor: me.role == UserRole.tutor,
    );
  }
}

final authControllerProvider =
    Provider<AuthController>((ref) => AuthController(ref));