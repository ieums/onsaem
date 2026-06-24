import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_tutor_profile.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class StudentTutorRatingStars extends StatelessWidget {
  const StudentTutorRatingStars({
    super.key,
    required this.rating,
    this.size = 16,
  });

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < rating.floor()
                ? Icons.star_rounded
                : (rating - i >= 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            size: size,
            color: AppColors.reviewHighlight,
          ),
      ],
    );
  }
}

class StudentPrimaryGradientButton extends StatelessWidget {
  const StudentPrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.shellOnSurfaceLight : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? [AppColors.studentInk, AppColors.primaryBlue]
                : [
                    AppColors.studentPoint.withValues(alpha: 0.45),
                    AppColors.primaryBlue.withValues(alpha: 0.45),
                  ],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(26),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudentTutorMetricChip extends StatelessWidget {
  const StudentTutorMetricChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: shell.detailBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 2),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                color: shell.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentTutorCompactCard extends StatelessWidget {
  const StudentTutorCompactCard({
    super.key,
    required this.tutor,
    required this.onViewProfile,
    required this.onSelect,
    this.showSubjectBadges = false,
    this.emphasized = false,
  });

  final StudentTutorProfile tutor;
  final VoidCallback onViewProfile;
  final VoidCallback onSelect;
  final bool showSubjectBadges;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final selectButtonTextColor = AppColors.studentInk;
    final borderColor = emphasized
        ? AppColors.studentPoint.withValues(alpha: 0.45)
        : shell.cardBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.studentPoint.withValues(alpha: 0.04)
            : shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: emphasized ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutor.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tutor.educationLine,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: shell.subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (tutor.isOnline)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.studentPoint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppColors.studentPoint.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    '접속중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.studentInk,
                    ),
                  ),
                ),
            ],
          ),
          if (showSubjectBadges) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final subject in tutor.subjects)
                  TutorSubjectBadge(subject: subject),
              ],
            ),
          ],
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudentTutorMetricChip(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.reviewHighlight,
                  label: '평점',
                  value: tutor.rating.toStringAsFixed(1),
                ),
                const SizedBox(width: 8),
                StudentTutorMetricChip(
                  label: '수업',
                  value: '${tutor.lessonCount}회',
                ),
                const SizedBox(width: 8),
                StudentTutorMetricChip(
                  label: '응답',
                  value: '${tutor.avgResponseMinutes}분',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: emphasized
                          ? AppColors.studentInk
                          : shell.cardBorder,
                      width: emphasized ? 1.5 : 1,
                    ),
                    foregroundColor: emphasized
                        ? AppColors.studentInk
                        : shell.titleColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '프로필 보기',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onSelect,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.studentPoint,
                    foregroundColor: selectButtonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '선택하기',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudentFlowAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudentFlowAppBar({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final pageBg = Theme.of(context).scaffoldBackgroundColor;

    return AppBar(
      backgroundColor: pageBg,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.arrow_back_rounded, color: shell.titleColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: shell.titleColor,
        ),
      ),
    );
  }
}
