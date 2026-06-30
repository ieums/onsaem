import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/matching/models/pending_confirm.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
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
              // 앱을 껐다 켜서 놓친 매칭 수락 요청이 있으면 복구 배너 노출.
              ...() {
                final pending = ref.watch(pendingConfirmProvider).valueOrNull;
                if (pending == null) return const <Widget>[];
                return [
                  _buildPendingConfirmBanner(context, shell, pending),
                  const SizedBox(height: 16),
                ];
              }(),
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
                          // 학생 강조색(연두)
                          color: AppColors.studentPoint,
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

  // 앱을 껐다 켜서 놓친 매칭 수락 요청 복구 배너.
  Widget _buildPendingConfirmBanner(
      BuildContext context, ShellTheme shell, PendingConfirm pc) {
    return Material(
      color: AppColors.studentPoint,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onTapPendingConfirm(pc),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.how_to_reg_rounded, color: Colors.black, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '강사가 입장을 기다려요',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pc.tutorName} 강사님 · 눌러서 수락하기',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTapPendingConfirm(PendingConfirm pc) async {
    final studentId = ref.read(currentUserProvider)?.id;
    if (studentId == null) return;
    // 세션을 다시 연결하고 수락/거절 다이얼로그를 띄운다(shell의 listener가 처리).
    await ref.read(studentMatchingSessionProvider.notifier).restorePendingConfirm(
          problemId: pc.problemId,
          studentId: studentId,
          subject: pc.subject ?? '',
          questionSummary: pc.questionSummary ?? '',
          tutorId: pc.tutorId,
        );
  }

  Widget _buildActionCards(BuildContext context) {
    final shell = ShellTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 라이트: 글씨 검정. 다크: 각 카드의 상징색(강사=연두, AI=보라)으로.
    Color titleFor(Color role) => isDark ? role : Colors.black;
    Color subFor(Color role) =>
        isDark ? role.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.6);

    return Row(
      children: [
        Expanded(
          child: _HomeActionCard(
            icon: Icons.school_outlined,
            title: '강사 찾기',
            subtitle: '실시간 매칭',
            backgroundColor: shell.cardBackground,
            borderColor: AppColors.studentPoint,
            titleColor: titleFor(AppColors.studentPoint),
            subtitleColor: subFor(AppColors.studentPoint),
            iconColor: AppColors.studentPoint,
            onTap: () => context.push(RoutePaths.studentProblemUpload),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HomeActionCard(
            icon: Icons.smart_toy_outlined,
            title: 'AI 튜터',
            subtitle: '언제든지 질문 가능',
            backgroundColor: shell.cardBackground,
            borderColor: AppColors.primaryBlue,
            titleColor: titleFor(AppColors.primaryBlue),
            subtitleColor: subFor(AppColors.primaryBlue),
            iconColor: AppColors.primaryBlue,
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
            const SizedBox(width: 8),
            // 진행 중(매칭 대기) 질문 수 / 최대 3개.
            async.maybeWhen(
              data: (items) {
                final active =
                    items.where((p) => p.status == 'PENDING').length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.studentPoint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '진행 중 $active/$maxOnHome',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: shell.titleColor,
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const Spacer(),
            async.maybeWhen(
              data: (items) => items
                          .where((p) => p.status == 'PENDING')
                          .length >
                      maxOnHome
                  ? GestureDetector(
                      onTap: () => context.push(RoutePaths.studentProblemList),
                      child: Row(
                        children: [
                          const Text(
                            '전체 보기',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 16, color: Colors.black),
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
            // 홈 미리보기는 '매칭 대기(PENDING)' 질문만 — 전체(매칭완료/만료/취소 등)는 마이페이지 목록에서.
            final visible =
                items.where((p) => p.status == 'PENDING').toList();
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 문제 이미지 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: item.imageUrls.isNotEmpty
                      ? Image.network(
                          ApiConstants.resolveImageUrl(item.imageUrls.first),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _thumbPlaceholder(shell),
                        )
                      : _thumbPlaceholder(shell),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProblemSubjectChip(subject: item.subject),
                        // 홈에선 상태 키워드(매칭 대기 등) 숨김 — 과목만.
                        if (categories.isNotEmpty)
                          Expanded(
                            child: Padding(
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
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 6),
                    // 등록 시간 + 지원 강사 수
                    Text(
                      '${_timeAgo(item.createdAt)} · 지원 강사 ${item.applicantCount}명',
                      style: TextStyle(fontSize: 12, color: shell.hintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 20, color: shell.chevronColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(ShellTheme shell) {
    return Container(
      color: shell.cardBorder.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: shell.hintColor, size: 22),
    );
  }

  static String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return '방금 전';
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    return '${d.inDays}일 전';
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
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
          ),
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
