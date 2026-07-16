import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';

import 'media_permissions.dart';

/// 강의실 입장 시 카메라·마이크 미허용 안내 다이얼로그.
///
/// 매칭 "수락" 직전 게이트가 막았을 때 호출한다(이 시점에 매칭은 취소됨).
/// 시스템 권한 팝업 대신 설정으로 유도한다.
///
/// 공용 [showConfirmDialog]로 렌더해 버튼 스타일을 통일하고,
/// 강의실은 shell 테마 밖이라 다크모드가 안 잡히므로 `shellDarkModeProvider` 기준
/// 테마를 명시적으로 넘긴다. (isTutor로 강조색 구분)
Future<void> showLessonPermissionDialog(
  BuildContext context,
  WidgetRef ref, {
  bool isTutor = false,
}) async {
  final theme =
      ref.read(shellDarkModeProvider) ? AppTheme.shellDark : AppTheme.shellLight;
  final open = await showConfirmDialog(
    context: context,
    title: '카메라·마이크 권한이 필요해요',
    message: '수업에 입장하려면 설정에서 카메라와 마이크를 허용해 주세요.\n매칭은 취소되었어요.',
    cancelText: '닫기',
    confirmText: '설정 열기',
    isTutor: isTutor,
    theme: theme,
  );
  if (open) MediaPermissions.openSettings();
}
