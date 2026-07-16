import 'package:shared_preferences/shared_preferences.dart';

/// 가입 직후 1회 '환영 보너스' 안내 다이얼로그를 띄우기 위한 로컬 플래그.
/// 가입 성공 시 예약하고, 홈(셸) 첫 진입에서 소비(consume)해 1회만 보여준다.
const String _kPendingWelcomeBonus = 'pending_welcome_bonus';

/// 가입 성공 시 호출 — 다음 홈 진입에서 환영 안내를 1회 띄우도록 예약.
Future<void> markPendingWelcomeBonus() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPendingWelcomeBonus, true);
  } catch (_) {
    // 저장 실패해도 치명적이지 않음(안내가 안 뜨는 정도).
  }
}

/// 예약돼 있으면 true를 한 번 반환하고 즉시 해제(중복 표시 방지).
Future<bool> consumePendingWelcomeBonus() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kPendingWelcomeBonus) ?? false) {
      await prefs.remove(_kPendingWelcomeBonus);
      return true;
    }
  } catch (_) {}
  return false;
}
