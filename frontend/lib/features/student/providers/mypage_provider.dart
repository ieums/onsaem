import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/features/student/models/mypage_models.dart';
import 'package:ieum/features/student/repositories/mypage_repository.dart';

final mypageRepositoryProvider = Provider<MypageRepository>(
  (ref) => MypageRepository(),
);

/// 내 프로필 (GET /auth/me) — {id, role, name, email, profileImageUrl, status}.
final meProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(mypageRepositoryProvider).getMe();
});

/// 내가 쓴 리뷰 목록.
final myReviewsProvider = FutureProvider.autoDispose<List<MyReview>>((ref) {
  return ref.watch(mypageRepositoryProvider).getMyReviews();
});

/// 내 신고 내역.
final myReportsProvider = FutureProvider.autoDispose<List<MyReport>>((ref) {
  return ref.watch(mypageRepositoryProvider).getMyReports();
});
