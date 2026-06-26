import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/tutor/data/tutor_repository.dart';

class TutorAvailabilityNotifier extends StateNotifier<bool> {
  // 앱 시작은 항상 오프라인. 강사가 직접 온라인으로 켜야 질문 신청 가능.
  TutorAvailabilityNotifier(this._repo, this._tutorId) : super(false);

  final TutorRepository _repo;
  final int? _tutorId;

  Future<void> toggle(bool value) async {
    state = value;
    if (_tutorId == null) return;
    try {
      await _repo.updateAvailability(_tutorId, available: value);
    } catch (_) {
      state = !value;
    }
  }
}

final tutorAvailabilityProvider =
    StateNotifierProvider<TutorAvailabilityNotifier, bool>((ref) {
  final tutorId = ref.watch(currentUserProvider)?.id;
  return TutorAvailabilityNotifier(TutorRepository(), tutorId);
});
