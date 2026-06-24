import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/screens/student_problem_status_screen.dart';
import 'package:ieum/features/student/widgets/student_problem_chips.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';

/// 내 질문 목록 화면. GET /problems/student.
/// 카드 탭 → 질문 현황(간략+강사현황) → 상세 → 분류 수정.
class StudentProblemListScreen extends ConsumerWidget {
  const StudentProblemListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
    final async = ref.watch(studentProblemsProvider);

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '내 질문',
              onBack: () => context.go(RoutePaths.studentHome),
            ),
            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.studentInk,
                onRefresh: () async => ref.refresh(studentProblemsProvider.future),
                child: async.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(
                        color: AppColors.studentInk,
                      ),
                    ),
                  ),
                  error: (e, _) => _MessageState(
                    shell: shell,
                    icon: Icons.error_outline,
                    title: '목록을 불러오지 못했어요',
                    subtitle: '잠시 후 다시 시도해 주세요.',
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return _MessageState(
                        shell: shell,
                        icon: Icons.assignment_outlined,
                        title: '등록한 질문이 없어요',
                        subtitle: '문제 사진을 올려 첫 질문을 등록해 보세요.',
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ProblemCard(
                        shell: shell,
                        item: items[i],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentProblemStatusScreen(problem: items[i]),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.shell,
    required this.item,
    required this.onTap,
  });

  final ShellTheme shell;
  final StudentProblemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: shell.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: shell.cardBorder.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProblemSubjectChip(subject: item.subject),
                const SizedBox(width: 8),
                ProblemStatusChip(status: item.status),
                const Spacer(),
                Icon(Icons.chevron_right, color: shell.chevronColor, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              (item.summary?.trim().isNotEmpty ?? false)
                  ? item.summary!.trim()
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatDate(item.createdAt),
                style: TextStyle(fontSize: 12.5, color: shell.hintColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}.${two(l.month)}.${two(l.day)}';
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.shell,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ShellTheme shell;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: shell.hintColor.withValues(alpha: 0.6)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: shell.titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: shell.hintColor),
        ),
      ],
    );
  }
}
