/// 사용자 역할. 백엔드의 "student" / "tutor" 문자열과 1:1 대응.
enum UserRole {
  student,
  tutor;

  /// 백엔드 문자열 → enum
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'tutor':
        return UserRole.tutor;
      default:
        throw ArgumentError('알 수 없는 role: $value');
    }
  }

  /// enum → 백엔드로 보낼 문자열 ("student" / "tutor")
  String get apiValue => name;
}

/// 로그인 / 회원가입 / 소셜 / refresh 응답의 data 부분.
/// { accessToken, refreshToken, role }
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final UserRole role;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      role: UserRole.fromString(json['role'] as String),
    );
  }
}

/// GET /auth/me 응답의 data 부분.
/// { id, role, name, email, profileImageUrl, status }
class UserProfile {
  final int id;
  final UserRole role;
  final String name;
  final String email;
  final String? profileImageUrl; // 소셜 아니면 없을 수 있음
  final String status;           // ACTIVE 등

  const UserProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      role: UserRole.fromString(json['role'] as String),
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      status: json['status'] as String,
    );
  }
}
/// 소셜 로그인 1단계(check) 결과.
/// - registered=true  → tokens 로 즉시 로그인
/// - registered=false → profile 프리필 들고 가입 폼으로 이동
class OAuthCheckResult {
  final bool registered;
  final AuthTokens? tokens;   // registered=true 일 때만
  final OAuthProfile? profile; // registered=false 일 때만

  const OAuthCheckResult({
    required this.registered,
    this.tokens,
    this.profile,
  });

  factory OAuthCheckResult.fromJson(Map<String, dynamic> json) {
    final registered = json['registered'] as bool;
    return OAuthCheckResult(
      registered: registered,
      tokens: registered
          ? AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>)
          : null,
      profile: registered
          ? null
          : OAuthProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }
}

/// 신규 소셜 사용자 가입 폼 프리필 정보 (이메일 미동의 시 null 가능).
class OAuthProfile {
  final String? email;
  final String? name;
  final String? profileImageUrl;

  const OAuthProfile({this.email, this.name, this.profileImageUrl});

  factory OAuthProfile.fromJson(Map<String, dynamic> json) {
    return OAuthProfile(
      email: json['email'] as String?,
      name: json['name'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
/// 소셜 가입 폼으로 넘기는 인자 (provider/token + 프리필 프로필).
class SocialSignupArgs {
  final String provider;       // "google" | "kakao" | "naver"
  final UserRole role;         // student | tutor
  final String token;          // 소셜 토큰 (서버 재검증용)
  final OAuthProfile profile;  // 프리필 (이름/이메일/사진)

  const SocialSignupArgs({
    required this.provider,
    required this.role,
    required this.token,
    required this.profile,
  });
}