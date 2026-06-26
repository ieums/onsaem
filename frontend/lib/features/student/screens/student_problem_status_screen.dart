import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/matching/repositories/matching_repository.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/models/student_tutor_profile.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/screens/student_problem_detail_screen.dart';
import 'package:ieum/features/student/widgets/student_problem_chips.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';

class StudentProblemStatusScreen extends ConsumerStatefulWidget {
  const StudentProblemStatusScreen({super.key, required this.problem});

  final StudentProblemModel problem;

  @override
  ConsumerState<StudentProblemStatusScreen> createState() =>
      _StudentProblemStatusScreenState();
}

class _StudentProblemStatusScreenState
    extends ConsumerState<StudentProblemStatusScreen> {
  List<StudentTutorProfile> _applicants = [];
  bool _loadingApplicants = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(studentMatchingSessionProvider);
    if (session != null && session.problemId == widget.problem.problemId) return;

    // searching 여부와 무관하게 세션을 복원한다.
    // (세션이 없으면 '선택하기'가 무반응이 되므로 — selectTutor가 state를 필요로 함)
    _loadingApplicants = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final studentId = ref.read(currentUserProvider)?.id;
      if (studentId == null) {
        setState(() => _loadingApplicants = false);
        return;
      }
      try {
        await ref.read(studentMatchingSessionProvider.notifier).resumeMatching(
              problemId: widget.problem.problemId,
              studentId: studentId,
              subject: widget.problem.subject ?? '',
              questionSummary: widget.problem.summary ?? '',
            );
      } catch (_) {
        // 세션 복원 실패 시 신청 목록만이라도 보여줌(선택은 제한될 수 있음)
        await _loadApplicants();
      } finally {
        if (mounted) setState(() => _loadingApplicants = false);
      }
    });
  }

  Future<void> _deleteQuestion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('질문 삭제'),
        content: const Text('이 질문을 삭제할까요? 삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(
                    color: AppColors.buttonDanger,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(studentMatchingSessionProvider);
    final hasActiveSession =
        session != null && session.problemId == widget.problem.problemId;
    if (hasActiveSession) {
      await ref
          .read(studentMatchingSessionProvider.notifier)
          .cancelMatching();
    } else {
      try {
        await MatchingRepository().cancelProblem(widget.problem.problemId);
      } catch (_) {}
    }
    if (!context.mounted) return;
    ref.invalidate(studentProblemsProvider);
    Navigator.of(context).pop();
  }

  Future<void> _loadApplicants() async {
    setState(() => _loadingApplicants = true);
    try {
      final list =
          await MatchingRepository().getApplicants(widget.problem.problemId);
      if (mounted) setState(() => _applicants = list.map(StudentTutorProfile.fromApplicant).toList());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingApplicants = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final session = ref.watch(studentMatchingSessionProvider);
    final useSession =
        session != null && session.problemId == widget.problem.problemId;
    final effectiveCandidates = useSession ? session.candidates : _applicants;
    final showLoading = !useSession && _loadingApplicants;
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme:
          baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '질문 현황',
              onBack: () => Navigator.of(context).pop(),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _SectionTitle(shell: shell, text: '학생 등록 문제'),
                  const SizedBox(height: 10),
                  _BriefCard(
                    shell: shell,
                    problem: widget.problem,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentProblemDetailScreen(
                              problem: widget.problem),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(shell: shell, text: '강사 현황'),
                  const SizedBox(height: 10),
                  if (showLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                            color: AppColors.studentInk),
                      ),
                    )
                  else if (effectiveCandidates.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 28),
                      decoration: BoxDecoration(
                        color: shell.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: shell.cardBorder.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline,
                              size: 40,
                              color: shell.hintColor.withValues(alpha: 0.7)),
                          const SizedBox(height: 12),
                          Text(
                            '아직 신청한 강사가 없어요',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: shell.titleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '잠시 후 강사들이 지원하면 알려드릴게요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12.5, color: shell.hintColor),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final tutor in effectiveCandidates) ...[
                      StudentTutorCompactCard(
                        tutor: tutor,
                        showSubjectBadges: true,
                        onViewProfile: () {
                          context.push(
                              '${RoutePaths.studentTutorProfile}/${tutor.id}');
                        },
                        onSelect: () {
                          ref
                              .read(studentMatchingSessionProvider.notifier)
                              .selectTutor(tutor.id);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _deleteQuestion(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.buttonDanger,
                        side: BorderSide(
                          color: AppColors.buttonDanger.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '질문 삭제',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.shell, required this.text});
  final ShellTheme shell;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: shell.titleColor,
      ),
    );
  }
}

class _BriefCard extends StatelessWidget {
  const _BriefCard({
    required this.shell,
    required this.problem,
    required this.onTap,
  });

  final ShellTheme shell;
  final StudentProblemModel problem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.studentPoint.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.studentInk.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProblemSubjectChip(subject: problem.subject),
                const SizedBox(width: 8),
                ProblemStatusChip(status: problem.status),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      '상세 보기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.studentInk,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18, color: AppColors.studentInk),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              (problem.summary?.trim().isNotEmpty ?? false)
                  ? problem.summary!.trim()
                  : '문제 요약 없음',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: shell.titleColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
