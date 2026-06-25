import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/applicant_model.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/screens/student_problem_detail_screen.dart';
import 'package:ieum/features/student/widgets/student_problem_chips.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';

/// 질문 현황(중간) 화면. [학생 등록 문제(간략) + 강사 현황(실제 지원강사)].
/// 위 '간략' 카드 탭 → 문제 상세. 아래는 GET /matching/{id}/applicants 로 지원강사를 보여준다.
class StudentProblemStatusScreen extends ConsumerWidget {
  const StudentProblemStatusScreen({super.key, required this.problem});

  final StudentProblemModel problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          final isPending = problem.status == 'PENDING';
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
                    problem: problem,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentProblemDetailScreen(problem: problem),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(shell: shell, text: '강사 현황'),
                  const SizedBox(height: 10),
                  _ApplicantsSection(shell: shell, problem: problem),
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    _StartMatchingButton(problemId: problem.problemId),
                    const SizedBox(height: 8),
                    _DeleteQuestionButton(problemId: problem.problemId),
                  ],
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

/// 위쪽 '간략' 카드 — 탭하면 상세로. 과목/상태 + 대분류·소분류 + 요약.
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
    final categories = [
      if ((problem.primaryType?.trim().isNotEmpty) ?? false)
        problem.primaryType!.trim(),
      if ((problem.secondaryType?.trim().isNotEmpty) ?? false)
        problem.secondaryType!.trim(),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.studentPoint.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.studentInk.withValues(alpha: 0.25)),
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
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in categories)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.studentInk.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.studentInk,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 아래쪽 강사 현황 — 실제 지원강사 목록(GET /matching/{id}/applicants).
class _ApplicantsSection extends ConsumerWidget {
  const _ApplicantsSection({required this.shell, required this.problem});
  final ShellTheme shell;
  final StudentProblemModel problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(problemApplicantsProvider(problem.problemId));

    return async.when(
      loading: () => _box(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.studentInk),
          ),
        ),
      ),
      error: (_, _) => _emptyBox('강사 현황을 불러오지 못했어요.'),
      data: (applicants) {
        if (applicants.isEmpty) {
          return _emptyBox(
            problem.status == 'PENDING'
                ? "아직 지원한 강사가 없어요. ‘강사 찾기 시작’을 누르면 강사들이 지원할 수 있어요."
                : '지원한 강사가 없어요.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '지원 강사 ${applicants.length}명',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.studentInk,
              ),
            ),
            const SizedBox(height: 10),
            for (final a in applicants) ...[
              _ApplicantCard(shell: shell, applicant: a),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _box({required Widget child}) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: shell.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: shell.cardBorder.withValues(alpha: 0.5)),
        ),
        child: child,
      );

  Widget _emptyBox(String text) => _box(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: Column(
            children: [
              Icon(Icons.people_outline,
                  size: 40, color: shell.hintColor.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: shell.hintColor),
              ),
            ],
          ),
        ),
      );
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.shell, required this.applicant});
  final ShellTheme shell;
  final ApplicantModel applicant;

  @override
  Widget build(BuildContext context) {
    final img = applicant.profileImageUrl;
    final resolved =
        (img != null && img.isNotEmpty) ? ApiConstants.resolveImageUrl(img) : null;
    final schoolMajor = [
      if (applicant.school.isNotEmpty) applicant.school,
      if (applicant.major.isNotEmpty) applicant.major,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shell.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.roleStudentBorder.withValues(alpha: 0.3),
            backgroundImage: resolved != null ? NetworkImage(resolved) : null,
            child: resolved == null
                ? const Icon(Icons.person, color: AppColors.studentInk)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.name.isEmpty ? '강사' : applicant.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
                if (schoolMajor.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    schoolMajor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: shell.hintColor),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 15, color: Color(0xFFE8A33D)),
                    const SizedBox(width: 2),
                    Text(
                      applicant.ratingAvg.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: shell.titleColor,
                      ),
                    ),
                    Text(
                      ' (${applicant.reviewCount})',
                      style: TextStyle(fontSize: 12, color: shell.hintColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '수업 ${applicant.lessonCount}회',
                      style: TextStyle(fontSize: 12, color: shell.hintColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// '강사 찾기 시작' — POST /matching/{id}/start 로 탐색을 시작하고 지원강사 목록을 갱신.
class _StartMatchingButton extends ConsumerStatefulWidget {
  const _StartMatchingButton({required this.problemId});
  final int problemId;

  @override
  ConsumerState<_StartMatchingButton> createState() =>
      _StartMatchingButtonState();
}

class _StartMatchingButtonState extends ConsumerState<_StartMatchingButton> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await ref.read(matchingRepositoryProvider).startMatching(widget.problemId);
      ref.invalidate(problemApplicantsProvider(widget.problemId));
      if (mounted) _snack('강사 찾기를 시작했어요. 지원이 들어오면 여기에 표시돼요.');
    } catch (_) {
      // 이미 탐색 중이거나 일시 오류 — 목록만 새로고침
      ref.invalidate(problemApplicantsProvider(widget.problemId));
      if (mounted) _snack('이미 강사를 찾고 있어요. 잠시만 기다려 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: _busy ? null : _start,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.studentInk,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : const Text('강사 찾기 시작',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

/// 질문 삭제(취소) — PENDING 질문을 지워 3개 제한 슬롯을 비운다.
class _DeleteQuestionButton extends ConsumerWidget {
  const _DeleteQuestionButton({required this.problemId});
  final int problemId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('질문 삭제'),
        content: const Text('이 질문을 삭제할까요? 삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제',
                style: TextStyle(
                    color: AppColors.logoutRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(problemRepositoryProvider).cancelProblem(problemId);
      ref.invalidate(studentProblemsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('질문을 삭제했어요.')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했어요. 잠시 후 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: TextButton.icon(
        onPressed: () => _delete(context, ref),
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        label: const Text('질문 삭제',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        style: TextButton.styleFrom(foregroundColor: AppColors.logoutRed),
      ),
    );
  }
}
