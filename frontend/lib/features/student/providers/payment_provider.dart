import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/student/models/payment_models.dart';
import 'package:ieum/features/student/repositories/payment_repository.dart';

/// 결제 레포지토리.
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(),
);

int? _studentId(Ref ref) => ref.watch(currentUserProvider)?.id;

/// 코인 잔액. 충전/환불 후 invalidate로 갱신.
final coinBalanceProvider =
    FutureProvider.autoDispose<CoinBalance?>((ref) async {
  final id = _studentId(ref);
  if (id == null) return null;
  return ref.watch(paymentRepositoryProvider).getCoinBalance(id);
});

/// 충전 패키지 목록(고정).
final coinPackagesProvider =
    FutureProvider.autoDispose<List<CoinPackage>>((ref) async {
  return ref.watch(paymentRepositoryProvider).getCoinPackages();
});

/// 코인 거래 내역.
final coinTransactionsProvider =
    FutureProvider.autoDispose<List<CoinTransaction>>((ref) async {
  final id = _studentId(ref);
  if (id == null) return const [];
  return ref.watch(paymentRepositoryProvider).getCoinTransactions(id);
});

/// 충전(결제) 내역.
final coinPaymentsProvider =
    FutureProvider.autoDispose<List<PaymentInfo>>((ref) async {
  final id = _studentId(ref);
  if (id == null) return const [];
  return ref.watch(paymentRepositoryProvider).getCoinPayments(id);
});

/// 구독 플랜 목록.
final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlan>>((ref) async {
  return ref.watch(paymentRepositoryProvider).getSubscriptionPlans();
});

/// 내 구독(없으면 null).
final mySubscriptionProvider =
    FutureProvider.autoDispose<Subscription?>((ref) async {
  final id = _studentId(ref);
  if (id == null) return null;
  return ref.watch(paymentRepositoryProvider).getMySubscription(id);
});
