import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/dio_client.dart';

/// 백엔드 `/health` 엔드포인트 연결 확인
final healthProvider = FutureProvider<String>((ref) async {
  final response = await dio.get('/health');
  return response.data.toString();
});
