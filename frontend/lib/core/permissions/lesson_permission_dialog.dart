import 'package:flutter/material.dart';

import 'media_permissions.dart';

/// 강의실 입장 시 카메라·마이크 미허용 안내 다이얼로그.
///
/// 매칭 "수락" 직전 게이트가 막았을 때 호출한다(이 시점에 매칭은 취소됨).
/// 시스템 권한 팝업 대신 설정으로 유도한다. 셸 테마(라/다)를 그대로 따른다.
Future<void> showLessonPermissionDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('카메라·마이크 권한이 필요해요'),
        content: const Text(
          '수업에 입장하려면 설정에서 카메라와 마이크를 허용해 주세요.\n'
          '매칭은 취소되었어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              MediaPermissions.openSettings();
            },
            child: const Text('설정 열기'),
          ),
        ],
      );
    },
  );
}
