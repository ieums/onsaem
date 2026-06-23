import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// 인터셉터를 타지 않는 '맨' Dio.
/// - refresh 호출과 '원래 요청 재시도'에 사용.
/// - dioClient 를 재사용하면 다시 인터셉터를 타서 무한루프가 되므로 분리.
final _bareDio = Dio(
  BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ),
);

/// ① 나가는 요청에 Authorization 자동 첨부
/// ② 401 응답이면 refresh 로 토큰 재발급 후 원래 요청 재시도
class AuthInterceptor extends Interceptor {
  /// 토큰을 붙이면 안 되는(= 인증 전) 경로들
  static const _noAuthPaths = [
    '/auth/oauth/',
    '/auth/student/signup',
    '/auth/tutor/signup',
    '/auth/student/login',
    '/auth/tutor/login',
    '/auth/refresh',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthFree =
        _noAuthPaths.any((p) => options.path.startsWith(p));

    if (!isAuthFree) {
      final token = await tokenStorage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final isRefreshCall =
        err.requestOptions.path.startsWith('/auth/refresh');

    // 401 이 아니거나, refresh 호출 자체가 실패한 거면 우리가 손 못 댐
    if (!is401 || isRefreshCall) {
      return handler.next(err);
    }

    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      return handler.next(err); // 저장된 refresh 없음 → 그냥 에러
    }

    try {
      // 1) refresh 로 새 토큰 발급 (회전됨: access·refresh 둘 다 새로 옴)
      final res = await _bareDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String;
      await tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      // 2) 실패했던 원래 요청을 새 토큰으로 재시도
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccess';
      final retried = await _bareDio.fetch(options);

      return handler.resolve(retried); // 성공 응답으로 되살림
    } catch (_) {
      // refresh 실패(만료 등) → 토큰 폐기, 로그아웃 상태로
      await tokenStorage.clear();
      return handler.next(err);
    }
  }
}