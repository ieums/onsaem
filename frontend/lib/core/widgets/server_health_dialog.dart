import 'package:flutter/material.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';

/// 서버 연결 상태 팝업 (닫기 가능). 공통 confirm 다이얼로그(단일 버튼)로 통일.
Future<void> showServerHealthDialog(
  BuildContext context, {
  required bool isSuccess,
  required String message,
}) async {
  await showConfirmDialog(
    context: context,
    title: isSuccess ? '서버 연결 성공' : '서버 연결 실패',
    message: isSuccess ? '서버 연결 상태: $message' : '서버 연결 실패: $message',
    cancelText: null,
    confirmText: '닫기',
  );
}
