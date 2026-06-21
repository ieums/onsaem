/// 사용자 역할. 백엔드의 "student" / "tutor" 문자열과 1:1 대응.
enum UserRole {
  student,
  tutor;

  /// 백엔드 문자열 → enum
  static UserRole fromString(String value) {
    switch (value) {
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