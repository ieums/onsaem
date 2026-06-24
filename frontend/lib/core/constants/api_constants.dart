import 'dart:io';
import 'package:flutter/foundation.dart';

abstract final class ApiConstants {
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);

  static String get baseUrl {
    if (isProduction) return 'http://3.35.10.251/api/v1';
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (Platform.isIOS) return 'http://localhost:8080/api/v1';
    return 'http://10.0.2.2:8080/api/v1';
  }

  /// 업로드 이미지 등 정적 리소스용 오리진(= baseUrl에서 `/api/v1` 제거).
  static String get assetBaseUrl {
    const suffix = '/api/v1';
    final b = baseUrl;
    return b.endsWith(suffix) ? b.substring(0, b.length - suffix.length) : b;
  }

  /// 저장된 이미지 URL을 표시용 절대 URL로 변환.
  /// - http(s)로 시작(S3/prod)하면 그대로
  /// - `/uploads/..` 같은 상대경로면 백엔드 오리진을 붙임
  static String resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return url.startsWith('/') ? '$assetBaseUrl$url' : '$assetBaseUrl/$url';
  }

  static String get wsUrl {
    if (isProduction) return 'ws://3.35.10.251:8080/ws-raw';
    if (kIsWeb) return 'ws://localhost:8080/ws-raw';
    if (Platform.isIOS) return 'ws://localhost:8080/ws-raw';
    return 'ws://10.0.2.2:8080/ws-raw';
  }
}
