import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/providers/student_notification_provider.dart';
import 'package:ieum/features/student/providers/student_shell_tab_provider.dart';
import 'package:ieum/features/student/screens/student_problem_status_screen.dart';
import 'package:ieum/features/student/widgets/student_notification_dialog.dart';
import 'package:ieum/features/student/widgets/student_problem_chips.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final pageBg = Theme.of(context).scaffoldBackgroundColor;

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
              const SizedBox(height: 28),
              _buildMyQuestions(context, shell),
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
            onTap: () => showStudentNotificationDialog(context, ref),
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
                          // 학생 고유색(연두 계열 잉크)
                          color: AppColors.studentInk,
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
            titleColor: AppColors.studentInk,
            subtitleColor: AppColors.studentInk.withValues(alpha: 0.75),
            iconColor: AppColors.studentInk,
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

  Widget _buildMyQuestions(BuildContext context, ShellTheme shell) {
    const maxOnHome = 3;
    final async = ref.watch(studentProblemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildSectionTitle(context, shell, '내 질문'),
            const Spacer(),
            async.maybeWhen(
              data: (items) => items
                          .where((p) => p.status != 'CANCELED')
                          .length >
                      maxOnHome
                  ? GestureDetector(
                      onTap: () => context.push(RoutePaths.studentProblemList),
                      child: Row(
                        children: [
                          Text(
                            '전체 보기',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.studentInk,
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 16, color: AppColors.studentInk),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        async.when(
          loading: () => _questionsHint(shell, '질문을 불러오는 중…'),
          error: (_, _) => _questionsHint(shell, '질문을 불러오지 못했어요.'),
          data: (items) {
            // 취소된 질문은 홈에 노출하지 않는다(마이페이지 내 질문에서 확인 가능).
            final visible =
                items.where((p) => p.status != 'CANCELED').toList();
            if (visible.isEmpty) {
              return _questionsHint(
                  shell, '아직 등록한 질문이 없어요. 사진을 올려 첫 질문을 등록해 보세요.');
            }
            final shown = visible.take(maxOnHome).toList();
            return Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _buildQuestionCard(context, shell, shown[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _questionsHint(ShellTheme shell, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: shell.hintColor),
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    ShellTheme shell,
    StudentProblemModel item,
  ) {
    final categories = [
      if ((item.primaryType?.trim().isNotEmpty) ?? false)
        item.primaryType!.trim(),
      if ((item.secondaryType?.trim().isNotEmpty) ?? false)
        item.secondaryType!.trim(),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentProblemStatusScreen(problem: item),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                  ProblemSubjectChip(subject: item.subject),
                  const SizedBox(width: 8),
                  ProblemStatusChip(status: item.status),
                  Expanded(
                    child: categories.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              categories.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: shell.hintColor,
                              ),
                            ),
                          ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: shell.chevronColor),
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
            ],
          ),
        ),
      ),
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
