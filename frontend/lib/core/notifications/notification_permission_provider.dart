import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_lifecycle_provider.dart';
import 'app_notification_service.dart';

/// OS 알림 권한 허용 여부.
///
/// 앱이 resume될 때(시스템 설정에서 바꾸고 돌아온 경우 포함) 자동 재평가되도록
/// [appLifecycleProvider]를 구독한다. 마이페이지 토글이 "OS 권한 + 앱 pref"를
/// 함께 반영하는 데 쓴다.
final notificationPermissionProvider = FutureProvider.autoDispose<bool>((ref) {
  ref.watch(appLifecycleProvider); // 생명주기 변화 시 재평가
  return AppNotificationService.instance.hasPermission();
});

/// 마이페이지 "푸시 알림 받기" 토글 공통 처리(학생·강사 동일).
///
/// 대원칙: 시스템 권한 팝업은 **사용자가 직접 토글을 켜는** 이 경로와 온보딩 일괄
/// 권한 화면에서만 뜬다.
/// - 켤 때: OS 권한 요청 → 허용되면 앱 pref on / 미허용이면 설정 유도(앱 pref off 유지)
/// - 끌 때: 앱 pref off (OS 권한 회수는 불가 → 앱 레벨에서만)
Future<void> handlePushToggle(
  BuildContext context,
  WidgetRef ref, {
  required bool enable,
  required Future<void> Function(bool) setPref,
}) async {
  if (!enable) {
    await setPref(false);
    ref.invalidate(notificationPermissionProvider);
    return;
  }

  final granted = await AppNotificationService.instance.requestPermission();
  ref.invalidate(notificationPermissionProvider);
  if (granted) {
    await setPref(true);
    return;
  }

  // 미허용(거부/영구거부) → 재요청 대신 설정으로 유도.
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('알림 권한이 필요해요. 설정에서 허용해 주세요.'),
      action: SnackBarAction(
        label: '설정',
        onPressed: () => AppNotificationService.instance.openSystemSettings(),
      ),
    ),
  );
}
