import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';

/// 가로 스크롤 과목·카테고리 필터 칩 (라이트/다크 공통)
/// 가로 스크롤 과목·카테고리 필터 칩 (라이트/다크 공통)
class ShellFilterChip extends StatelessWidget {
  const ShellFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// 선택 시 강조색. 안 주면 기본 파랑(튜터 화면 호환).
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = selectedColor ?? AppColors.primaryBlue;
    // 통일 스타일: 채움 없이 '테두리만 특징색 + 흰/다크 표면 + 검정/특징색 글씨'.
    // 선택은 특징색 보더(굵게) + 진한 글씨로, 미선택은 회색 보더 + 흐린 글씨로 구분.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : scheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? (isDark ? accent : Colors.black)
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 주간/월간·입금/출금 등 작은 세그먼트 칩
class ShellSegmentChip extends StatelessWidget {
  const ShellSegmentChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onFill = AppColors.onPrimaryFill(Theme.of(context).brightness);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : scheme.surfaceContainerHighest,
          border: selected
              ? null
              : Border.all(color: scheme.outline, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? onFill : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// [showMenu] 항목 행 배경 — 미선택 시 메뉴 surface와 맞춤
Color shellPopupMenuRowColor(BuildContext context, {required bool selected}) {
  return selected ? AppColors.primaryBlue : Colors.transparent;
}

/// 바텀시트 상단 드래그 핸들
class ShellSheetHandle extends StatelessWidget {
  const ShellSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
