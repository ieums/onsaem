import 'package:dio/dio.dart';
import 'package:ieum/core/network/dio_client.dart';
import 'package:ieum/features/student/models/payment_models.dart';

/// 결제(payment) 도메인 API 클라이언트.
/// PaymentController는 ResponseEntity 직접 반환 → res.data를 그대로 파싱(언래핑 없음).
class PaymentRepository {
  final Dio _dio;

  PaymentRepository({Dio? dio}) : _dio = dio ?? dioClient;

  // ── 코인 ──

  Future<CoinBalance> getCoinBalance(int studentId) async {
    final res = await _dio.get('/payments/coins/balance',
        queryParameters: {'studentId': studentId});
    return CoinBalance.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<CoinTransaction>> getCoinTransactions(int studentId) async {
    final res = await _dio.get('/payments/coins/transactions',
        queryParameters: {'studentId': studentId});
    return (res.data as List)
        .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CoinPackage>> getCoinPackages() async {
    final res = await _dio.get('/payments/coins/packages');
    return (res.data as List)
        .map((e) => CoinPackage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 충전 결제 시작 — 대기 결제 생성. 반환된 merchantId/amount로 포트원 결제창을 띄운다.
  Future<PaymentInfo> createCoinPayment({
    required int studentId,
    required int coinPackageId,
  }) async {
    final res = await _dio.post('/payments/coins/charge', data: {
      'studentId': studentId,
      'coinPackageId': coinPackageId,
    });
    return PaymentInfo.fromJson(res.data as Map<String, dynamic>);
  }

  /// 충전 결제 완료 확인 — 포트원 결제 후 받은 paymentId로 서버 검증·코인 적립.
  Future<CoinBalance> completeCoinPayment({
    required String merchantId,
    required String portonePaymentId,
    String method = 'CARD',
  }) async {
    final res = await _dio.post('/payments/coins/confirm', data: {
      'merchantId': merchantId,
      'portonePaymentId': portonePaymentId,
      'method': method,
    });
    return CoinBalance.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<PaymentInfo>> getCoinPayments(int studentId) async {
    final res = await _dio.get('/payments/coins/payments',
        queryParameters: {'studentId': studentId});
    return (res.data as List)
        .map((e) => PaymentInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CoinBalance> refundCoinPayment(int paymentId, {String? reason}) async {
    final res = await _dio.post(
      '/payments/coins/payments/$paymentId/refund',
      data: reason == null ? null : {'reason': reason},
    );
    return CoinBalance.fromJson(res.data as Map<String, dynamic>);
  }

  // ── 구독 ──

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final res = await _dio.get('/payments/subscriptions/plans');
    return (res.data as List)
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 내 구독 — 없으면 null.
  Future<Subscription?> getMySubscription(int studentId) async {
    final res = await _dio.get('/payments/subscriptions/me',
        queryParameters: {'studentId': studentId});
    final data = res.data;
    if (data == null || (data is Map && data.isEmpty)) return null;
    return Subscription.fromJson(data as Map<String, dynamic>);
  }

  Future<Subscription> cancelSubscription(int studentId) async {
    final res = await _dio.delete('/payments/subscriptions',
        queryParameters: {'studentId': studentId});
    return Subscription.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Subscription> toggleAutoRenew({
    required int studentId,
    required bool autoRenew,
  }) async {
    final res = await _dio.patch('/payments/subscriptions/auto-renew', data: {
      'studentId': studentId,
      'autoRenew': autoRenew,
    });
    return Subscription.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentInfo> createSubscriptionPayment({
    required int studentId,
    required int subscriptionPlanId,
    required bool autoRenew,
  }) async {
    final res = await _dio.post('/payments/subscriptions/charge', data: {
      'studentId': studentId,
      'subscriptionPlanId': subscriptionPlanId,
      'autoRenew': autoRenew,
    });
    return PaymentInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Subscription> completeSubscriptionPayment({
    required String merchantId,
    required String portonePaymentId,
    String method = 'CARD',
    required bool autoRenew,
  }) async {
    final res = await _dio.post('/payments/subscriptions/confirm', data: {
      'merchantId': merchantId,
      'portonePaymentId': portonePaymentId,
      'method': method,
      'autoRenew': autoRenew,
    });
    return Subscription.fromJson(res.data as Map<String, dynamic>);
  }
}
