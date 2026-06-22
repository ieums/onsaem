import 'package:dio/dio.dart';

import 'package:ieum/core/network/dio_client.dart';
import 'package:ieum/features/tutor/data/settlement_models.dart';

/// 정산 API 호출. baseUrl에 이미 /api/v1 이 포함되어 경로는 /settlements 로 시작한다.
/// 정산 컨트롤러는 본문을 ApiResponse로 감싸지 않으므로 res.data를 직접 파싱한다.
class SettlementRepository {
  final Dio _dio;

  SettlementRepository({Dio? dio}) : _dio = dio ?? dioClient;

  Future<List<SettlementResponse>> fetchByTutor(int tutorId) async {
    final res = await _dio.get(
      '/settlements',
      queryParameters: {'tutorId': tutorId},
    );
    return (res.data as List)
        .map((e) => SettlementResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SettlementSummaryResponse> fetchSummary(int tutorId) async {
    final res = await _dio.get(
      '/settlements/summary',
      queryParameters: {'tutorId': tutorId},
    );
    return SettlementSummaryResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SettlementResponse> requestWithdraw(int settlementId, int tutorId) async {
    final res = await _dio.post(
      '/settlements/$settlementId/withdraw',
      queryParameters: {'tutorId': tutorId},
    );
    return SettlementResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// 일괄 출금 요청
  Future<BulkWithdrawResponse> requestBulkWithdraw(int tutorId) async {
    final res = await _dio.post(
      '/settlements/withdraw-all',
      queryParameters: {'tutorId': tutorId},
    );
    return BulkWithdrawResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
