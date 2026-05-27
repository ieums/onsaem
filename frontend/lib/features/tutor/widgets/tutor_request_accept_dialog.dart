import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/utils/won_format_util.dart';
import 'package:ieum/features/tutor/data/tutor_request_list_dummy_data.dart';

/// 문제 신청/새 질문 **수락** 확인 모달.
///
/// `true` = 모달에서 수락, `false`/null = 취소·닫기.
/// 모달 수락 후 이동 화면은 호출부에서 처리 (추후 디자인).
Future<bool?> showTutorRequestAcceptDialog(
  BuildContext context,
  TutorRequestListItem item,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final width = math.min(MediaQuery.sizeOf(dialogContext).width - 48, 360.0);
      final scheme = Theme.of(dialogContext).colorScheme;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '질문을 수락하시겠어요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '수락하면 학생과 매칭됩니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _AcceptModalDetailBox(item: item),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.onPrimaryFill(
                            Theme.of(dialogContext).brightness,
                          ),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '수락',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _AcceptModalDetailBox extends StatelessWidget {
  const _AcceptModalDetailBox({required this.item});

  final TutorRequestListItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SubjectSection(item: item),
          const SizedBox(height: 12),
          _InfoRow(label: '예상 수업 시간', value: '${item.classMinutes}분'),
          const SizedBox(height: 10),
          _InfoRow(
            label: '예상 금액',
            value: formatWon(item.priceWon),
            valueColor: AppColors.primaryBlue,
            valueBold: true,
          ),
        ],
      ),
    );
  }

}

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({required this.item});

  final TutorRequestListItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '과목',
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.detailSubject,
                textAlign: TextAlign.right,
                style: valueStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.chapter.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.chapter,
                  textAlign: TextAlign.right,
                  style: valueStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
