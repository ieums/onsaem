import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/student_tutor_dummy_data.dart';
import 'package:ieum/features/student/models/student_lesson_pricing.dart';
import 'package:ieum/features/student/models/student_tutor_profile.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class StudentTutorProfileScreen extends ConsumerStatefulWidget {
  const StudentTutorProfileScreen({
    super.key,
    required this.tutorId,
  });

  final String tutorId;

  @override
  ConsumerState<StudentTutorProfileScreen> createState() =>
      _StudentTutorProfileScreenState();
}

class _StudentTutorProfileScreenState extends ConsumerState<StudentTutorProfileScreen> {
  int _tabIndex = 0;

  StudentTutorProfile? get _tutor => StudentTutorDummyData.byId(widget.tutorId);

  bool get _canSelect {
    final session = ref.watch(studentMatchingSessionProvider);
    return session?.status == StudentMatchingSessionStatus.selectingTutor &&
        session!.candidateIds.contains(widget.tutorId);
  }

  void _selectTutor() {
    ref.read(studentMatchingSessionProvider.notifier).selectTutor(widget.tutorId);
    context.push(RoutePaths.studentQuestionStatus);
  }

  @override
  Widget build(BuildContext context) {
    final tutor = _tutor;
    final session = ref.watch(studentMatchingSessionProvider);
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    if (tutor == null) {
      return Theme(
        data: theme,
        child: Scaffold(
          appBar: StudentFlowAppBar(title: '강사 프로필'),
          body: const Center(child: Text('강사 정보를 찾을 수 없습니다.')),
        ),
      );
    }

    final lessonPrice = session?.lessonPrice ??
        StudentLessonPricing.priceForDifficulty(StudentLessonPricing.medium);

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          final pageBg = Theme.of(context).scaffoldBackgroundColor;

          return Scaffold(
            appBar: StudentFlowAppBar(title: '강사 프로필'),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      _ProfileSummaryCard(tutor: tutor),
                      const SizedBox(height: 16),
                      _SegmentTabs(
                        tabIndex: _tabIndex,
                        reviewCount: tutor.reviewCount,
                        onChanged: (index) => setState(() => _tabIndex = index),
                      ),
                      const SizedBox(height: 16),
                      if (_tabIndex == 0)
                        _IntroContent(tutor: tutor)
                      else
                        _ReviewsContent(tutor: tutor),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: shell.cardBorder,
                    ),
                    ColoredBox(
                      color: pageBg,
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '예상 크레딧',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.2,
                                      color: shell.hintColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    StudentLessonPricing.formattedPrice(
                                      lessonPrice,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      color: shell.titleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: StudentPrimaryGradientButton(
                                label: _canSelect ? '선택하기' : '매칭 요청하기',
                                enabled: _canSelect,
                                onPressed: _canSelect ? _selectTutor : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.tutor});

  final StudentTutorProfile tutor;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tutor.educationLine,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: shell.subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (tutor.isOnline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.studentPoint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricChip(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.reviewHighlight,
                  label: '평점',
                  value: tutor.rating.toStringAsFixed(1),
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: '수업',
                  value: '${tutor.lessonCount}회',
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: '응답',
                  value: '${tutor.avgResponseMinutes}분',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({
    required this.tabIndex,
    required this.reviewCount,
    required this.onChanged,
  });

  final int tabIndex;
  final int reviewCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: shell.detailBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _SegmentTab(
            label: '소개',
            selected: tabIndex == 0,
            onTap: () => onChanged(0),
          ),
          _SegmentTab(
            label: '리뷰 $reviewCount',
            selected: tabIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Expanded(
      child: Material(
        color: selected ? shell.cardBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.studentPoint : shell.hintColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent({required this.tutor});

  final StudentTutorProfile tutor;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ContentCard(
          title: '한줄소개',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tutor.introLine,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: shell.titleColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tutor.introBody,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: shell.subtitleColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ContentCard(
          title: '과외 스타일',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in tutor.styles)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.studentPoint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    style,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.studentPoint,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ContentCard(
          title: '담당 과목',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final subject in tutor.subjects)
                TutorSubjectBadge(subject: subject),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsContent extends StatelessWidget {
  const _ReviewsContent({required this.tutor});

  final StudentTutorProfile tutor;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Column(
      children: [
        for (final review in tutor.reviews) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: shell.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: shell.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.studentLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: shell.titleColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      review.dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: shell.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StudentTutorRatingStars(rating: review.rating, size: 16),
                const SizedBox(height: 10),
                Text(
                  review.body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: shell.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: shell.titleColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
