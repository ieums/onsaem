import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

import '../utils/simulator_detector.dart';

/// 카메라·마이크 권한 공통 헬퍼.
///
/// 대원칙: **시스템 권한 팝업은 온보딩 직후 일괄 권한 화면에서만** 뜬다.
/// 기능 자리(수업 입장/촬영 등)에서는 절대 `.request()`를 호출하지 않고
/// [hasCameraMic]/[hasCamera]로 상태만 확인한 뒤, 미허용이면 [openSettings]로 유도한다.
/// ([requestCameraMic]는 일괄 권한 화면 등 "사용자 명시 요청" 경로 전용)
abstract final class MediaPermissions {
  static bool _ok(PermissionStatus s) => s.isGranted || s.isLimited;

  /// 카메라+마이크가 모두 사용 가능한지.
  static Future<bool> hasCameraMic() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    return _ok(cam) && _ok(mic);
  }

  /// 카메라만 사용 가능한지.
  static Future<bool> hasCamera() async => _ok(await Permission.camera.status);

  /// 강의실 입장 게이트(매칭 "수락" 직전 호출).
  /// web·iOS 시뮬레이터는 하드웨어/권한 개념이 없어 통과시키고,
  /// 그 외는 카메라+마이크 보유 여부로 입장 허용 여부를 결정한다.
  /// (시스템 팝업은 띄우지 않음 — 미허용이면 호출측이 설정으로 유도)
  static Future<bool> ensureForLessonEntry() async {
    if (kIsWeb) return true;
    if (await isIosSimulator()) return true;
    return hasCameraMic();
  }

  /// 카메라+마이크 요청(일괄 권한 화면 등 명시적 요청 경로 전용).
  static Future<bool> requestCameraMic() async {
    final r = await [Permission.camera, Permission.microphone].request();
    return _ok(r[Permission.camera] ?? PermissionStatus.denied) &&
        _ok(r[Permission.microphone] ?? PermissionStatus.denied);
  }

  /// 앱 권한 설정 화면 열기.
  static Future<bool> openSettings() => openAppSettings();
}
