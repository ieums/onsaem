import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';

/// 백엔드가 잔액 부족 시 던지는 메시지("코인이 부족합니다 ...") 판별.
bool isCoinShortageMessage(String? message) {
  if (message == null) return false;
  return message.contains('코인이 부족') || message.contains('코인 부족');
}

/// 코인 부족 안내 → '충전하기' 누르면 충전 화면으로 이동.
/// 충전 화면에서 돌아오면 true(호출부가 원래 동작을 재시도하도록).
Future<bool> promptRechargeAndReturn(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('코인이 부족해요',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('계속하려면 코인을 충전해야 해요.\n지금 충전할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.studentPoint,
            foregroundColor: Colors.black,
          ),
          child: const Text('충전하기',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  // 충전 화면(포트원 SDK 결제)으로. 돌아오면 호출부가 재시도.
  await context.push(RoutePaths.studentCreditRecharge);
  return true;
}
