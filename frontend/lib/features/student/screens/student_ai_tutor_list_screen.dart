import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/screens/student_ai_tutor_screen.dart';
import 'package:ieum/features/student/screens/student_problem_upload_screen.dart';
import 'package:ieum/features/student/widgets/student_problem_chips.dart';

/// AI 튜터 탭. 내가 올린 문제 목록 → 문제 선택 → 그 문제로 AI 튜터 채팅.
class StudentAiTutorListScreen extends ConsumerWidget {
  const StudentAiTutorListScreen({super.key});

  void _registerForAiTutor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StudentProblemUploadScreen(forAiTutor: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ShellTheme.of(context);
    final async = ref.watch(studentProblemsProvider);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'AI 튜터',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: shell.titleColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                '질문할 문제를 선택하거나 새로 등록하세요',
                style: TextStyle(fontSize: 13.5, color: shell.hintColor),
              ),
            ),
            // 새 문제 등록 → 등록 후 바로 그 문제로 AI 튜터 채팅 (forAiTutor)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _registerForAiTutor(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('새 문제 등록하기',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.studentInk,
                    side: BorderSide(
                        color: AppColors.studentInk.withValues(alpha: 0.5)),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.studentInk,
                onRefresh: () async =>
                    ref.refresh(studentProblemsProvider.future),
                child: async.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.studentInk),
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
                        title: '등록한 문제가 없어요',
                        subtitle: '문제 사진을 올리면 AI 튜터에게 질문할 수 있어요.',
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ProblemCard(
                        shell: shell,
                        item: items[i],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentAiTutorScreen(
                                problemId: items[i].problemId,
                                problemSummary: items[i].summary,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
                Icon(Icons.smart_toy_outlined,
                    color: AppColors.studentInk, size: 20),
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