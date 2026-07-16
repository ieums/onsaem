import 'package:dio/dio.dart';

import 'package:ieum/core/network/dio_client.dart';
import 'package:ieum/features/tutor/data/settlement_models.dart';

/// 정산 API 호출. baseUrl에 이미 /api/v1 이 포함되어 경로는 /settlements 로 시작한다.
/// 정산 컨트롤러는 본문을 ApiResponse로 감싸지 않으므로 res.data를 직접 파싱한다.
class SettlementRepository {
  final Dio _dio;

  SettlementRepository({Dio? dio}) : _dio = dio ?? dioClient;

  // 대상 강사는 서버가 JWT(principal)로 판별하므로 tutorId 쿼리는 보내지 않는다.
  // (보내도 서버가 무시 — 잘못된 계약이라 제거)

  /// 응답이 기대한 타입(List/Map)이 아니면(예: 401 에러 객체) 깔끔한 메시지로.
  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    throw DioException(
      requestOptions: RequestOptions(path: '/settlements'),
      error: '정산 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: RequestOptions(path: '/settlements'),
      error: '정산 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
    );
  }

  Future<List<SettlementResponse>> fetchByTutor(int tutorId) async {
    final res = await _dio.get('/settlements');
    return _asList(res.data)
        .map((e) => SettlementResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 정산 예정(완료됐지만 미정산) 강의 목록.
  Future<List<PendingSettlementResponse>> fetchPending(int tutorId) async {
    final res = await _dio.get('/settlements/pending');
    return _asList(res.data)
        .map((e) => PendingSettlementResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SettlementSummaryResponse> fetchSummary(int tutorId) async {
    final res = await _dio.get('/settlements/summary');
    return SettlementSummaryResponse.fromJson(_asMap(res.data));
  }

  Future<SettlementResponse> requestWithdraw(int settlementId, int tutorId) async {
    final res = await _dio.post('/settlements/$settlementId/withdraw');
    return SettlementResponse.fromJson(_asMap(res.data));
  }

  /// 일괄 출금 요청
  Future<BulkWithdrawResponse> requestBulkWithdraw(int tutorId) async {
    final res = await _dio.post('/settlements/withdraw-all');
    return BulkWithdrawResponse.fromJson(_asMap(res.data));
  }

  /// 정산 계좌 조회 — 로그인 강사 본인(/me). (ApiResponse 래핑이라 data 언래핑)
  Future<SettlementAccount> fetchAccount() async {
    final res = await _dio.get('/tutors/me/settlement-account');
    final data = res.data['data'] as Map<String, dynamic>;
    return SettlementAccount.fromJson(data);
  }

  /// 정산 계좌 등록·수정 — 로그인 강사 본인(/me).
  Future<SettlementAccount> updateAccount({
    required String bank,
    required String account,
    required String holder,
  }) async {
    final res = await _dio.patch(
      '/tutors/me/settlement-account',
      data: {'bank': bank, 'account': account, 'holder': holder},
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return SettlementAccount.fromJson(data);
  }
}
