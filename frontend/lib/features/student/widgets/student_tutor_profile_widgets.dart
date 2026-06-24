import 'package:flutter/material.dart';
import 'package:ieum/core/constants/api_constants.dart';
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
    final borderColor = emphasized
        ? AppColors.studentPoint.withValues(alpha: 0.45)
        : shell.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.studentPoint.withValues(alpha: 0.04)
            : shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: emphasized ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onViewProfile,
                child: _buildAvatar(shell),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tutor.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: shell.titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (tutor.isInLesson)
                          _InLessonBadge()
                        else
                          _OnlineBadge(isOnline: tutor.isOnline),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppColors.reviewHighlight,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          tutor.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: shell.titleColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '수업 ${tutor.lessonCount}회',
                          style: TextStyle(
                            fontSize: 12,
                            color: shell.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: tutor.isInLesson ? null : onSelect,
                style: FilledButton.styleFrom(
                  backgroundColor: tutor.isInLesson
                      ? Colors.grey.withValues(alpha: 0.3)
                      : AppColors.studentPoint,
                  foregroundColor: tutor.isInLesson
                      ? Colors.grey
                      : AppColors.studentInk,
                  disabledBackgroundColor:
                      Colors.grey.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '선택하기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (showSubjectBadges && tutor.subjects.isNotEmpty) ...[
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
        ],
      ),
    );
  }

  Widget _buildAvatar(ShellTheme shell) {
    const size = 44.0;
    final url = tutor.profileImageUrl;
    if (url != null) {
      return ClipOval(
        child: Image.network(
          ApiConstants.resolveImageUrl(url),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _placeholderAvatar(shell, size),
        ),
      );
    }
    return _placeholderAvatar(shell, size);
  }

  Widget _placeholderAvatar(ShellTheme shell, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: shell.cardBorder.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.55,
          color: shell.hintColor,
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.studentPoint.withValues(alpha: 0.35)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isOnline ? AppColors.studentInk : Colors.grey,
        ),
      ),
      child: Text(
        isOnline ? '온라인' : '오프라인',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isOnline ? AppColors.studentInk : Colors.grey,
        ),
      ),
    );
  }
}

class _InLessonBadge extends StatelessWidget {
  const _InLessonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primaryBlue),
      ),
      child: const Text(
        '수업 중',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryBlue,
        ),
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
