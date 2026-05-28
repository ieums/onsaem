import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';

/// 가로 스크롤 과목·카테고리 필터 칩 (라이트/다크 공통)
class ShellFilterChip extends StatelessWidget {
  const ShellFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : scheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? onFill : scheme.onSurfaceVariant,
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
