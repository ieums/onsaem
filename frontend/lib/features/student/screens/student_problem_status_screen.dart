import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/screens/student_problem_detail_screen.dart';
import 'package:ieum/features/student/widgets/student_problem_chips.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';

/// 질문 현황(중간) 화면. 와이어프레임의 [학생 등록 문제(간략) + 강사현황].
/// 위 '간략' 카드 탭 → 문제 상세. 아래 강사현황/활성화는 placeholder(매칭팀 영역).
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
                  _TutorStatusPlaceholder(shell: shell),
                  const SizedBox(height: 16),
                  _ActivateButton(shell: shell),
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

/// 위쪽 '간략' 카드 — 탭하면 상세로.
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
          ],
        ),
      ),
    );
  }
}

/// 아래쪽 강사현황 — placeholder(매칭팀 영역).
class _TutorStatusPlaceholder extends StatelessWidget {
  const _TutorStatusPlaceholder({required this.shell});
  final ShellTheme shell;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: shell.cardBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline,
              size: 40, color: shell.hintColor.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            '강사 매칭 단계에서 진행돼요',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: shell.titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "‘강사 찾기 시작’을 누르면 강사들이 지원할 수 있어요.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: shell.hintColor),
          ),
        ],
      ),
    );
  }
}

/// '강사 찾기 시작' 활성화 버튼 — 현재 placeholder(매칭팀 연결 예정).
class _ActivateButton extends StatelessWidget {
  const _ActivateButton({required this.shell});
  final ShellTheme shell;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('강사 찾기는 매칭 단계에서 연결될 예정이에요.')),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.studentPoint,
          foregroundColor: AppColors.studentInk,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          '강사 찾기 시작',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
