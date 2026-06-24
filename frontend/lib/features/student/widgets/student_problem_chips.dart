import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/student/utils/problem_enum_labels.dart';

/// 옅은 채움 + 진한 글씨 칩(학생 컬러 규칙).
class ProblemChip extends StatelessWidget {
  const ProblemChip({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// 과목 칩(학생 진한 연두).
class ProblemSubjectChip extends StatelessWidget {
  const ProblemSubjectChip({super.key, required this.subject});
  final String? subject;

  @override
  Widget build(BuildContext context) =>
      ProblemChip(text: subjectLabel(subject), color: AppColors.studentInk);
}

/// 상태 칩(상태별 색).
class ProblemStatusChip extends StatelessWidget {
  const ProblemStatusChip({super.key, required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'PENDING' => const Color(0xFFE8A33D),
      'MATCHED' => const Color(0xFF2E9E6B),
      'RESOLVED' => const Color(0xFF6B7280),
      'CANCELED' => AppColors.logoutRed,
      _ => const Color(0xFF6B7280),
    };
    return ProblemChip(text: statusLabel(status), color: color);
  }
}
