import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';

/// 강사 화면 공통 버튼 스타일 — 테두리만 강사 특징색(primaryBlue), 내부는 흰/다크 표면.
/// - 라이트: 안쪽 흰색 + 특징색 보더 + 검정 글씨.
/// - 다크: 안쪽 다크 카드색(shellSurfaceDark) + 특징색 글씨 + 특징색 보더.
ButtonStyle tutorOutlinedButtonStyle(
  bool isDark, {
  double radius = 12,
  Size? minimumSize,
}) {
  final bg = isDark ? AppColors.shellSurfaceDark : Colors.white;
  return OutlinedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: isDark ? AppColors.primaryBlue : Colors.black,
    side: const BorderSide(color: AppColors.primaryBlue),
    disabledForegroundColor: Colors.grey,
    disabledBackgroundColor: bg,
    minimumSize: minimumSize,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}
