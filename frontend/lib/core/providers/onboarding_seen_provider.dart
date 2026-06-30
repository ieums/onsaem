import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 역할별 "온보딩 봤음" 영속 플래그.
///
/// redirect 는 동기라 SharedPreferences(async)를 직접 await 할 수 없으므로,
/// main() 에서 [loadOnboardingSeen] 으로 미리 읽어 [onboardingSeenProvider] 에 올려두고
/// redirect 는 이 StateProvider 를 동기로 읽어 분기한다.
/// (기존 onboarding_screen.dart 의 _notificationPromptedKey 와 동일 패턴)
const String _kSeenStudent = 'onboarding_seen_student';
const String _kSeenTutor = 'onboarding_seen_tutor';

class OnboardingSeen {
  const OnboardingSeen({this.student = false, this.tutor = false});

  final bool student;
  final bool tutor;

  OnboardingSeen copyWith({bool? student, bool? tutor}) => OnboardingSeen(
        student: student ?? this.student,
        tutor: tutor ?? this.tutor,
      );

  /// 역할별 시청 여부 조회.
  bool seenFor({required bool isTutor}) => isTutor ? tutor : student;
}

final onboardingSeenProvider =
    StateProvider<OnboardingSeen>((ref) => const OnboardingSeen());

/// 앱 시작 시 1회: 저장된 플래그를 읽어 프로바이더에 로드.
Future<void> loadOnboardingSeen(ProviderContainer container) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    container.read(onboardingSeenProvider.notifier).state = OnboardingSeen(
      student: prefs.getBool(_kSeenStudent) ?? false,
      tutor: prefs.getBool(_kSeenTutor) ?? false,
    );
  } catch (_) {
    // 읽기 실패 시 기본값(미시청) 유지 — 최악의 경우 온보딩이 한 번 더 뜨는 정도.
  }
}

/// 완료/건너뛰기 시: 해당 역할 플래그를 즉시(프로바이더) + 영속(prefs) 저장.
/// 프로바이더를 먼저 갱신해 redirect 가 곧바로 통과하도록 한다.
Future<void> markOnboardingSeen(
  ProviderContainer container, {
  required bool isTutor,
}) async {
  container.read(onboardingSeenProvider.notifier).update(
        (s) => isTutor ? s.copyWith(tutor: true) : s.copyWith(student: true),
      );
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isTutor ? _kSeenTutor : _kSeenStudent, true);
  } catch (_) {
    // 영속 실패해도 이번 세션 동안은 프로바이더 값으로 동작.
  }
}
