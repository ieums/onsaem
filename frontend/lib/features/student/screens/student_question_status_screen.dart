import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_lesson_pricing.dart';
import 'package:ieum/features/student/models/student_tutor_profile.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/utils/student_question_text_util.dart';
import 'package:ieum/features/student/widgets/student_problem_image_viewer.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class StudentQuestionStatusScreen extends ConsumerWidget {
  const StudentQuestionStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(studentMatchingSessionProvider, (previous, next) {
      if (next == null && previous != null && context.mounted) {
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
        if (!isCurrentRoute) return;
        context.go(RoutePaths.studentHome);
      }
    });

    final session = ref.watch(studentMatchingSessionProvider);
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    if (session == null || !session.showOnHomePending) {
      return Theme(
        data: theme,
        child: const Scaffold(body: SizedBox.shrink()),
      );
    }

    final tutor = session.selectedTutor;
    final isConnected = session.status == StudentMatchingSessionStatus.connected;
    final isConnecting = session.status == StudentMatchingSessionStatus.connecting;
    final isSelecting = session.status == StudentMatchingSessionStatus.selectingTutor;
    final isWaitingExpert = session.waitingForSubjectExpert;

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);

          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '질문 상태',
              onBack: () => context.go(RoutePaths.studentHome),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        _QuestionInfoCard(session: session),
                        const SizedBox(height: 24),
                        Text(
                          isWaitingExpert ? '강사 배정' : '배정된 강사',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: shell.titleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isWaitingExpert)
                          _TutorStatusCard(
                            title: '담당 강사 배정 대기 중',
                            subtitle:
                                '${session.subject} 담당 강사가 배정되면 알림으로 알려드릴게요.',
                          )
                        else if (isSelecting)
                          _TutorStatusCard(
                            title: '강사를 선택해 주세요',
                            subtitle: '배정된 강사 후보 중 한 분을 선택하면 수업이 연결돼요.',
                            actionLabel: '강사 선택하기',
                            onAction: () =>
                                context.push(RoutePaths.studentTutorSelection),
                          )
                        else if (tutor != null)
                          _AssignedTutorCard(
                            tutor: tutor,
                            onViewProfile: () {
                              context.push(
                                '${RoutePaths.studentTutorProfile}/${tutor.id}',
                              );
                            },
                            onChangeTutor: isConnecting || isConnected
                                ? () => _confirmChangeTutor(context, ref)
                                : null,
                          ),
                        if (isConnected) ...[
                          const SizedBox(height: 24),
                          Text(
                            '준비 완료!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.studentPoint,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '강사님이 대기 중입니다. 강의실로 입장하여 수업을 시작하세요.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: shell.titleColor,
                            ),
                          ),
                        ] else if (isConnecting) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.studentPoint,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '선택하신 강사와 연결하고 있어요...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: shell.subtitleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (isWaitingExpert) ...[
                          const SizedBox(height: 8),
                          Text(
                            StudentQuestionTextUtil.waitingLabel(session.startedAt),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: shell.subtitleColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isConnected || isConnecting)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '예상 크레딧 ${StudentLessonPricing.formattedPrice(session.lessonPrice)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: shell.subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StudentPrimaryGradientButton(
                            label: '강의실 입장하기',
                            enabled: isConnected,
                            onPressed: isConnected
                                ? () => context.push(RoutePaths.studentClassroom)
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmChangeTutor(BuildContext context, WidgetRef ref) async {
    final isDark = ref.read(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
    final confirmButtonTextColor =
        isDark ? AppColors.shellOnSurfaceLight : Colors.white;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: theme,
          child: Builder(
            builder: (themedContext) {
              final shell = ShellTheme.of(themedContext);

              return AlertDialog(
                backgroundColor: shell.cardBackground,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  '다른 강사 찾기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
                content: Text(
                  '선택하신 강사 연결을 취소하고\n다른 강사 후보를 다시 볼까요?',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: shell.subtitleColor,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: shell.subtitleColor,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.studentPoint,
                      foregroundColor: confirmButtonTextColor,
                    ),
                    child: const Text(
                      '다른 강사 보기',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    ref.read(studentMatchingSessionProvider.notifier).returnToTutorSelection();
    context.push(RoutePaths.studentTutorSelection);
  }
}

class _TutorStatusCard extends StatelessWidget {
  const _TutorStatusCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: shell.titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: shell.subtitleColor,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.studentPoint, width: 1.5),
                  foregroundColor: AppColors.studentPoint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionInfoCard extends StatelessWidget {
  const _QuestionInfoCard({required this.session});

  final StudentMatchingSession session;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final (badgeLabel, badgeColor) = switch (session.status) {
      StudentMatchingSessionStatus.connected => ('매칭됨', AppColors.studentPoint),
      StudentMatchingSessionStatus.connecting =>
        ('연결 중', AppColors.reviewHighlight),
      StudentMatchingSessionStatus.selectingTutor =>
        ('강사 선택', AppColors.studentPoint),
      _ when session.waitingForSubjectExpert =>
        ('배정 대기', AppColors.reviewHighlight),
      _ => ('매칭 중', shell.hintColor),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '질문 정보',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: shell.titleColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session.problemImageBytes != null)
                StudentProblemImageThumbnail(
                  imageBytes: session.problemImageBytes!,
                  size: 76,
                  borderRadius: 12,
                )
              else
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: shell.detailBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.studentPoint.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.studentPoint,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TutorSubjectBadge(subject: session.subject),
                    const SizedBox(height: 8),
                    Text(
                      session.questionSummary,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      StudentQuestionTextUtil.waitingLabel(session.startedAt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: shell.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignedTutorCard extends StatelessWidget {
  const _AssignedTutorCard({
    required this.tutor,
    required this.onViewProfile,
    this.onChangeTutor,
  });

  final StudentTutorProfile tutor;
  final VoidCallback onViewProfile;
  final VoidCallback? onChangeTutor;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder),
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
                      color: AppColors.studentPoint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AssignedTutorMetric(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.reviewHighlight,
                  label: '평점',
                  value: tutor.rating.toStringAsFixed(1),
                ),
                const SizedBox(width: 8),
                _AssignedTutorMetric(
                  label: '수업',
                  value: '${tutor.lessonCount}회',
                ),
                const SizedBox(width: 8),
                _AssignedTutorMetric(
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
                    side: const BorderSide(
                      color: AppColors.studentPoint,
                      width: 1.5,
                    ),
                    foregroundColor: AppColors.studentPoint,
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
              if (onChangeTutor != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onChangeTutor,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: shell.cardBorder),
                      foregroundColor: shell.subtitleColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '다른 강사 찾기',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignedTutorMetric extends StatelessWidget {
  const _AssignedTutorMetric({
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
