import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/constants/api_constants.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    backgroundColor: shell.cardBackground, // 내부 흰색(라이트)/표면(다크)
                    // 다크모드에선 글씨·아이콘을 특징색으로(라이트는 검정).
                    foregroundColor: isDark ? AppColors.studentPoint : Colors.black,
                    side: const BorderSide(color: AppColors.studentPoint),
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
                color: AppColors.studentPoint,
                onRefresh: () async =>
                    ref.refresh(studentProblemsProvider.future),
                child: async.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.studentPoint),
                  ),
                  error: (e, _) => _MessageState(
                    shell: shell,
                    icon: Icons.error_outline,
                    title: '목록을 불러오지 못했어요',
                    subtitle: '잠시 후 다시 시도해 주세요.',
                  ),
                  data: (all) {
                    // AI 튜터로 물어볼 수 있는 문제만: 매칭완료·풀이완료(=복습에서 질문)·취소됨은 제외.
                    final items = all
                        .where((p) =>
                            p.status != 'MATCHED' &&
                            p.status != 'RESOLVED' &&
                            p.status != 'CANCELED')
                        .toList();
                    if (items.isEmpty) {
                      return _MessageState(
                        shell: shell,
                        icon: Icons.assignment_outlined,
                        title: '질문할 문제가 없어요',
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
    // 한 줄로 얇게: 썸네일 + (과목·날짜 / 요약) + AI 아이콘.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: shell.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: shell.cardBorder.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: item.imageUrls.isNotEmpty
                    ? Image.network(
                        ApiConstants.resolveImageUrl(item.imageUrls.first),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _thumb(),
                      )
                    : _thumb(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ProblemSubjectChip(subject: item.subject),
                      const Spacer(),
                      Text(
                        _formatDate(item.createdAt),
                        style:
                            TextStyle(fontSize: 11.5, color: shell.hintColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (item.summary?.trim().isNotEmpty ?? false)
                        ? item.summary!.trim()
                        : '문제 요약 없음',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: shell.titleColor,
                    ),
                  ),
                ],
              ),
            ),
            // 이 카드를 누르면 'AI와 대화하는 채팅방'에 들어간다는 단서.
            // 작게(칩) 둬서 한 줄 카드 균형을 해치지 않게.
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.studentPoint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: AppColors.studentPoint),
                  SizedBox(width: 4),
                  Text(
                    '질문하기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.studentPoint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        color: shell.cardBorder.withValues(alpha: 0.3),
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: shell.hintColor, size: 22),
      );

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