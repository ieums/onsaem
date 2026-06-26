import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// iOS 시뮬레이터 여부.
/// 시뮬엔 카메라/마이크 하드웨어가 없어 권한이 permanentlyDenied로 잡히므로,
/// 오디오 전용 강의에서 권한 게이트를 건너뛰는 판별에 쓴다.
Future<bool> isIosSimulator() async {
  if (kIsWeb) return false;
  if (defaultTargetPlatform != TargetPlatform.iOS) return false;
  try {
    final info = await DeviceInfoPlugin().iosInfo;
    return !info.isPhysicalDevice; // 시뮬레이터면 isPhysicalDevice=false
  } catch (_) {
    return false;
  }
}
