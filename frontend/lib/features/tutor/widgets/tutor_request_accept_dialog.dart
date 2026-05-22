import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
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

      return Dialog(
        backgroundColor: Colors.white,
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
                const Text(
                  '질문을 수락하시겠어요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D26),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '수락하면 학생과 매칭됩니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9AA3B2),
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
                          foregroundColor: const Color(0xFF1A1D26),
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
                          foregroundColor: Colors.white,
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

  static const _hintColor = Color(0xFF9AA3B2);
  static const _labelColor = Color(0xFF1A1D26);
  static const _detailBoxColor = Color(0xFFF3F4F8);

  static const _subjectValueStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _labelColor,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _detailBoxColor,
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
            value: _formatWon(item.priceWon),
            valueColor: AppColors.primaryBlue,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  static String _formatWon(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return '$buffer원';
  }
}

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({required this.item});

  final TutorRequestListItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '과목',
          style: TextStyle(
            fontSize: 13,
            color: _AcceptModalDetailBox._hintColor,
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
                style: _AcceptModalDetailBox._subjectValueStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.chapter.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.chapter,
                  textAlign: TextAlign.right,
                  style: _AcceptModalDetailBox._subjectValueStyle,
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
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _AcceptModalDetailBox._hintColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? _AcceptModalDetailBox._labelColor,
          ),
        ),
      ],
    );
  }
}
