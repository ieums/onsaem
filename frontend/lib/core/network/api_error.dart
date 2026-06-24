import 'package:dio/dio.dart';

/// Dio 예외에서 백엔드가 내려준 message를 추출한다.
/// 백엔드 에러 응답은 { success, message, data } 형태.
/// 메시지가 없으면 네트워크 상태 또는 fallback 문구로 대체.
String apiErrorMessage(Object error, {String fallback = '잠시 후 다시 시도해주세요.'}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map &&
        data['message'] is String &&
        (data['message'] as String).trim().isNotEmpty) {
      return data['message'] as String;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return '네트워크 연결을 확인해주세요.';
      default:
        break;
    }
  }
  return fallback;
}