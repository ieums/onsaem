import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/utils/list_pagination.dart';
import 'package:ieum/core/widgets/list_pagination_controls.dart';
import 'package:ieum/features/student/data/student_home_dummy_data.dart';
import 'package:ieum/features/student/data/student_review_dummy_data.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/providers/student_notification_provider.dart';
import 'package:ieum/features/student/providers/student_shell_tab_provider.dart';
import 'package:ieum/features/student/screens/student_review_detail_screen.dart';
import 'package:ieum/features/student/utils/student_question_text_util.dart';
import 'package:ieum/features/student/widgets/student_notification_dialog.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  static const _starColor = Color(0xFFF5A623);

  int _recentLessonsPageIndex = 0;
  Timer? _pendingTickTimer;

  @override
  void dispose() {
    _pendingTickTimer?.cancel();
    super.dispose();
  }

  void _ensurePendingTickTimer(bool enabled) {
    if (enabled) {
      _pendingTickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      return;
    }
    _pendingTickTimer?.cancel();
    _pendingTickTimer = null;
  }

  List<StudentRecentLesson> get _pagedRecentLessons {
    return ListPagination.slice(
      StudentHomeDummyData.recentLessons,
      pageIndex: _safeRecentLessonsPageIndex,
      pageSize: StudentHomeDummyData.recentLessonsPageSize,
    );
  }

  int get _recentLessonsPageCount => ListPagination.pageCount(
        StudentHomeDummyData.recentLessons.length,
        StudentHomeDummyData.recentLessonsPageSize,
      );

  int get _safeRecentLessonsPageIndex =>
      ListPagination.clampPageIndex(
        _recentLessonsPageIndex,
        _recentLessonsPageCount,
      );

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final pageBg = Theme.of(context).scaffoldBackgroundColor;
    final matchingSession = ref.watch(studentMatchingSessionProvider);
    final isSessionActive = matchingSession != null &&
        matchingSession.status != StudentMatchingSessionStatus.connected;
    _ensurePendingTickTimer(isSessionActive);

    return ColoredBox(
      color: pageBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, shell),
              const SizedBox(height: 20),
              _buildActionCards(context),
              if (matchingSession != null && isSessionActive) ...[
                const SizedBox(height: 28),
                _buildSectionTitle(context, shell, '매칭 대기 중인 질문'),
                const SizedBox(height: 12),
                _ActivePendingQuestionCard(session: matchingSession),
              ],
              const SizedBox(height: 28),
              _buildSectionTitle(context, shell, '최근 수업 이력'),
              const SizedBox(height: 12),
              for (final lesson in _pagedRecentLessons) ...[
                _buildRecentLessonCard(context, shell, lesson),
                const SizedBox(height: 10),
              ],
              ListPaginationControls(
                pageIndex: _safeRecentLessonsPageIndex,
                pageCount: _recentLessonsPageCount,
                onPrevious: () => setState(
                  () => _recentLessonsPageIndex = _safeRecentLessonsPageIndex - 1,
                ),
                onNext: () => setState(
                  () => _recentLessonsPageIndex = _safeRecentLessonsPageIndex + 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ShellTheme shell) {
    final hasUnread = ref
        .watch(studentNotificationInboxProvider)
        .any((item) => !item.isRead);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '학생 홈',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: shell.titleColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showStudentNotificationDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: shell.cardBorder),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: shell.titleColor,
                    size: 22,
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.logoutRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.shellOnSurfaceLight : AppColors.white;
    final subtitleColor = isDark
        ? AppColors.shellSubtitleLight
        : AppColors.white.withValues(alpha: 0.85);

    return Row(
      children: [
        Expanded(
          child: _HomeActionCard(
            icon: Icons.school_outlined,
            title: '강사 찾기',
            subtitle: '실시간 매칭',
            backgroundColor: AppColors.studentPoint,
            titleColor: textColor,
            subtitleColor: subtitleColor,
            iconColor: textColor,
            onTap: () => context.push(RoutePaths.studentProblemUpload),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HomeActionCard(
            icon: Icons.smart_toy_outlined,
            title: 'AI 튜터',
            subtitle: '언제든지 질문 가능',
            backgroundColor: AppColors.primaryBlue,
            titleColor: textColor,
            subtitleColor: subtitleColor,
            iconColor: textColor,
            onTap: () {
              ref.read(studentShellTabIndexProvider.notifier).state =
                  studentShellAiTutorTabIndex;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    ShellTheme shell,
    String title,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: shell.titleColor,
      ),
    );
  }

  void _openReviewDetail(StudentRecentLesson lesson) {
    final review = StudentReviewDummyData.findById(lesson.id);
    if (review == null) return;

    final theme = Theme.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: theme,
          child: StudentReviewDetailScreen(item: review),
        ),
      ),
    );
  }

  Widget _buildRecentLessonCard(
    BuildContext context,
    ShellTheme shell,
    StudentRecentLesson lesson,
  ) {
    return Material(
      color: shell.cardBackground,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openReviewDetail(lesson),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: shell.cardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TutorSubjectBadge(subject: lesson.subject),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lesson.tutorName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: shell.titleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.question,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: shell.subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.recordedAtLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: shell.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _StarRating(
                  rating: lesson.rating,
                  starColor: _starColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePendingQuestionCard extends StatelessWidget {
  const _ActivePendingQuestionCard({required this.session});

  final StudentMatchingSession session;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final canSelectTutor =
        session.status == StudentMatchingSessionStatus.selectingTutor;
    final tutor = session.selectedTutor;
    final tutorLabel = switch (session.status) {
      StudentMatchingSessionStatus.connecting ||
      StudentMatchingSessionStatus.connected =>
        tutor?.name ?? '강사 연결 중',
      StudentMatchingSessionStatus.selectingTutor => '강사 선택하기',
      _ => '담당 강사 배정 대기 중',
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(RoutePaths.studentTutorSelection),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TutorSubjectBadge(subject: session.subject),
                        const Spacer(),
                        Text(
                          StudentQuestionTextUtil.waitingLabel(session.startedAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: shell.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      session.questionSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: shell.titleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: shell.cardBorder),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canSelectTutor
                  ? () => context.push(RoutePaths.studentTutorSelection)
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: canSelectTutor
                          ? AppColors.studentPoint
                          : shell.hintColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tutorLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: canSelectTutor
                              ? AppColors.studentPoint
                              : shell.subtitleColor,
                        ),
                      ),
                    ),
                    if (canSelectTutor)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.studentPoint,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.rating,
    required this.starColor,
  });

  final double rating;
  final Color starColor;

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
            size: 16,
            color: starColor,
          ),
      ],
    );
  }
}
