import 'package:flutter/material.dart';
import 'package:ieum/features/tutor/theme/tutor_subject_colors.dart';

/// 과목 태그 (라이트/다크 배지 색 자동 적용)
class TutorSubjectBadge extends StatelessWidget {
  const TutorSubjectBadge({
    super.key,
    required this.subject,
  });

  final String subject;

  @override
  Widget build(BuildContext context) {
    final (textColor, backgroundColor) = TutorSubjectColors.badgeColors(
      subject,
      Theme.of(context).brightness,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        subject,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
