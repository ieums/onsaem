import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 액세스/리프레시 토큰을 휴대폰 보안 저장소
/// (iOS Keychain / Android Keystore)에 보관
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // 저장소 안에서 토큰을 구분하는 '이름표'(키)
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// 로그인 성공 시: 두 토큰을 한 번에 저장
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// 액세스 토큰 꺼내기 (없으면 null)
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  /// 리프레시 토큰 꺼내기 (없으면 null)
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// 로그아웃 시: 저장된 토큰 전부 삭제
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

/// 앱 전체에서 공유하는 단일 인스턴스.
/// (dio_client.dart 가 top-level `dioClient` 를 쓰는 것과 같은 패턴)
final tokenStorage = TokenStorage();