import 'package:flutter/material.dart';

/// 서버 연결 상태 팝업 (닫기 가능)
Future<void> showServerHealthDialog(
  BuildContext context, {
  required bool isSuccess,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(isSuccess ? '서버 연결 성공' : '서버 연결 실패'),
        ],
      ),
      content: SelectableText(
        isSuccess ? '서버 연결 상태: $message' : '서버 연결 실패: $message',
        style: const TextStyle(fontSize: 15, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}
