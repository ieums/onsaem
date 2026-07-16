import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';
import 'package:ieum/features/matching/repositories/matching_repository.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/models/student_tutor_profile.dart';
import 'package:ieum/features/student/providers/payment_provider.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/screens/student_problem_detail_screen.dart';
import 'package:ieum/features/student/utils/coin_shortage.dart';
import 'package:ieum/features/student/widgets/student_action_button_style.dart';
import 'package:ieum/features/student/widgets/student_problem_chips.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';
import 'student_ai_tutor_screen.dart';

class StudentProblemStatusScreen extends ConsumerStatefulWidget {
  const StudentProblemStatusScreen({super.key, required this.problem});

  final StudentProblemModel problem;

  @override
  ConsumerState<StudentProblemStatusScreen> createState() =>
      _StudentProblemStatusScreenState();
}

class _StudentProblemStatusScreenState
    extends ConsumerState<StudentProblemStatusScreen> {
  // 기본 30분 강의 비용(백엔드 LessonPolicy.BASE_COST_COIN과 동일).
  static const _lessonCostCoins = 50;

  List<StudentTutorProfile> _applicants = [];
  bool _loadingApplicants = false;

  /// 강사 선택(매칭 확정) 직전 잔액 체크 — 50코인 미만이면 충전 유도(강사 헛대기 방지).
  Future<void> _onSelectTutor(String tutorId) async {
    int balance;
    try {
      balance =
          (await ref.read(coinBalanceProvider.future))?.availableBalance ?? 0;
    } catch (_) {
      balance = 0;
    }
    if (!mounted) return;
    if (balance < _lessonCostCoins) {
      final went = await promptRechargeAndReturn(context,
          theme: ref.read(shellDarkModeProvider)
              ? AppTheme.shellDark
              : AppTheme.shellLight);
      if (!went || !mounted) return;
      ref.invalidate(coinBalanceProvider);
      int after;
      try {
        after =
            (await ref.read(coinBalanceProvider.future))?.availableBalance ?? 0;
      } catch (_) {
        after = 0;
      }
      if (!mounted || after < _lessonCostCoins) return; // 충전 안 했으면 선택 보류
    }
    ref.read(studentMatchingSessionProvider.notifier).selectTutor(tutorId);
  }

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
    final ok = await showConfirmDialog(
      context: context,
      title: '질문 삭제',
      message: '이 질문을 삭제할까요?\n삭제하면 되돌릴 수 없어요.',
      cancelText: '취소',
      confirmText: '삭제',
      isDanger: true,
      theme: ref.read(shellDarkModeProvider)
          ? AppTheme.shellDark
          : AppTheme.shellLight,
    );
    if (!ok || !mounted) return;
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
          baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.studentScaffoldLight,
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
                            color: AppColors.studentPoint),
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
                        onSelect: () => _onSelectTutor(tutor.id),
                      ),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentAiTutorScreen(
                              problemId: widget.problem.problemId,
                              problemSummary: session?.questionSummary,
                            ),
                          ),
                        );
                      },
                      // 아이콘만 특징색, 글씨는 검정(다크는 특징색) 유지.
                      icon: const Icon(Icons.smart_toy_outlined,
                          size: 18, color: AppColors.studentPoint),
                      label: Text(
                        'AI 튜터에게 물어보기',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.studentPoint : Colors.black,
                        ),
                      ),
                      style: studentOutlinedButtonStyle(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteQuestion(context),
                      // 삭제는 위험 동작 → 아이콘만 빨강, 글씨는 검정(다크는 흰색), 보더 빨강.
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.buttonDanger),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.shellSurfaceDark : Colors.white,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        side: const BorderSide(color: AppColors.buttonDanger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      label: const Text(
                        '질문 삭제하기',
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
          // 학생 홈 문제 카드와 동일한 배경/테두리로 통일
          color: shell.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: shell.cardBorder),
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
                    const Text(
                      '상세 보기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.studentPoint,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.studentPoint),
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
