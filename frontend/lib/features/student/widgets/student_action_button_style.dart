import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';

/// 학생 화면 공통 버튼 스타일 — 홈 '강사 찾기' 카드와 동일한 룩.
/// - 라이트: 안쪽 흰색 + 특징색(studentPoint) 보더 + 검정 글씨.
/// - 다크: 안쪽 다크 카드색(shellSurfaceDark) + 특징색 글씨 + 특징색 보더.
ButtonStyle studentOutlinedButtonStyle(
  bool isDark, {
  double radius = 12,
  Size? minimumSize,
}) {
  // 다크모드 배경은 순검정이 아니라 강사찾기 카드와 같은 surface 색.
  final bg = isDark ? AppColors.shellSurfaceDark : Colors.white;
  return OutlinedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: isDark ? AppColors.studentPoint : Colors.black,
    side: const BorderSide(color: AppColors.studentPoint),
    disabledForegroundColor: Colors.grey,
    disabledBackgroundColor: bg,
    minimumSize: minimumSize,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}
