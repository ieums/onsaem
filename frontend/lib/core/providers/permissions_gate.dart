import 'package:shared_preferences/shared_preferences.dart';

/// "온보딩 후 일괄 권한 안내 화면을 이미 띄웠는가" 영속 플래그.
///
/// 일괄 안내는 첫 실행에 **1회만**. 거부자는 이후 기능별 기존 게이트가 처리하므로
/// 여기서 다시 띄우지 않는다. (onboarding_seen_provider 와 동일 패턴, prefs 직접 사용)
const String _kPermissionsPrompted = 'permissions_prompted';

Future<bool> wasPermissionsPrompted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPermissionsPrompted) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> markPermissionsPrompted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPermissionsPrompted, true);
  } catch (_) {
    // 실패해도 치명적이지 않음 — 다음 첫 진입에서 한 번 더 뜨는 정도.
  }
}
