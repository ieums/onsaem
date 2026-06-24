import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_lesson_pricing.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class StudentTutorSelectionScreen extends ConsumerStatefulWidget {
  const StudentTutorSelectionScreen({super.key});

  @override
  ConsumerState<StudentTutorSelectionScreen> createState() =>
      _StudentTutorSelectionScreenState();
}

class _StudentTutorSelectionScreenState
    extends ConsumerState<StudentTutorSelectionScreen> {
  bool _nonSubjectDialogHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNonSubjectDialog());
  }

  Future<void> _maybeShowNonSubjectDialog() async {
    if (_nonSubjectDialogHandled || !mounted) return;

    final session = ref.read(studentMatchingSessionProvider);
    if (session == null ||
        !session.isNonSubjectOnlyMatch ||
        session.hasWaitedForSubjectExpert) {
      return;
    }

    _nonSubjectDialogHandled = true;
    final isDark = ref.read(shellDarkModeProvider);
    final theme = _flowTheme(isDark);

    final waitForExpert = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
                  '담당 과목 강사 대기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
                content: Text(
                  '담당 과목이 아닌 강사들만 매칭되었어요.\n'
                  '담당 과목 강사님이 매칭되실 때까지 기다리시겠습니까?',
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
                      '지금 선택할게요',
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
                      foregroundColor: AppColors.studentInk,
                    ),
                    child: const Text(
                      '기다릴게요',
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

    if (!mounted || waitForExpert != true) return;

    ref.read(studentMatchingSessionProvider.notifier).waitForSubjectExpert();
    context.go(RoutePaths.studentHome);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(studentMatchingSessionProvider, (previous, next) {
      if (next == null && previous != null && context.mounted) {
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
        if (!isCurrentRoute) return;
        context.go(RoutePaths.studentHome);
      }
    });

    final session = ref.watch(studentMatchingSessionProvider);
    final isDark = ref.watch(shellDarkModeProvider);
    final theme = _flowTheme(isDark);

    if (session == null ||
        session.status != StudentMatchingSessionStatus.selectingTutor) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (isCurrentRoute &&
          session != null &&
          session.showOnHomePending &&
          context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (ModalRoute.of(context)?.isCurrent != true) return;
          context.go(RoutePaths.studentHome);
        });
      }
      return Theme(
        data: theme,
        child: const Scaffold(body: SizedBox.shrink()),
      );
    }

    final candidates = session.candidates;

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);

          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '강사 선택',
              onBack: () => context.go(RoutePaths.studentHome),
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '수락한 강사 ${candidates.length}명',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: shell.titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '학력·소개·리뷰를 확인하고 강사를 선택해 주세요.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: shell.subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TutorSubjectBadge(subject: session.subject),
                        const SizedBox(height: 8),
                        Text(
                          '예상 크레딧 ${StudentLessonPricing.formattedPrice(session.lessonPrice)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: shell.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: candidates.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tutor = candidates[index];
                        return StudentTutorCompactCard(
                          tutor: tutor,
                          showSubjectBadges: true,
                          onViewProfile: () {
                            context.push(
                              '${RoutePaths.studentTutorProfile}/${tutor.id}',
                            );
                          },
                          onSelect: () {
                            ref
                                .read(studentMatchingSessionProvider.notifier)
                                .selectTutor(tutor.id);
                            context.push(RoutePaths.studentQuestionStatus);
                          },
                        );
                      },
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

  ThemeData _flowTheme(bool isDark) {
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
  }
}
