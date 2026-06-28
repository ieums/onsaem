import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';
import 'package:ieum/features/matching/repositories/matching_repository.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/screens/student_problem_detail_screen.dart';
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
      colorScheme:
          baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.studentScaffoldLight,
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
                color: AppColors.studentPoint,
                onRefresh: () async => ref.refresh(studentProblemsProvider.future),
                child: async.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(
                        color: AppColors.studentPoint,
                      ),
                    ),
                  ),
                  error: (e, _) => _MessageState(
                    shell: shell,
                    icon: Icons.error_outline,
                    title: '목록을 불러오지 못했어요',
                    subtitle: '잠시 후 다시 시도해 주세요.',
                  ),
                  data: (all) {
                    // 취소(CANCELED)된 질문은 '내 질문'에 노출하지 않는다(이미지도 삭제돼 보여줄 게 없음).
                    final items = all
                        .where((p) => p.status != 'CANCELED')
                        .toList();
                    // 동시 등록 제한(최대 3개)에 걸리는 건 매칭 대기(PENDING) 질문 수.
                    final activeCount =
                        all.where((p) => p.status == 'PENDING').length;
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          _ActiveLimitHeader(shell: shell, active: activeCount),
                          const SizedBox(height: 40),
                          _MessageState(
                            shell: shell,
                            icon: Icons.assignment_outlined,
                            title: '등록한 질문이 없어요',
                            subtitle: '문제 사진을 올려 첫 질문을 등록해 보세요.',
                            embedded: true,
                          ),
                        ],
                      );
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        _ActiveLimitHeader(shell: shell, active: activeCount),
                        const SizedBox(height: 16),
                        for (var i = 0; i < items.length; i++) ...[
                          Builder(builder: (_) {
                            final item = items[i];
                            // 탐색 중(PENDING)인 질문만 '질문 현황'(강사 선택)으로,
                            // 매칭완료·풀이완료·만료는 보기전용 상세로 보낸다.
                            final isActive =
                                item.status == 'PENDING' || item.searching;
                            return _ProblemCard(
                              shell: shell,
                              item: item,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => isActive
                                        ? StudentProblemStatusScreen(
                                            problem: item)
                                        : StudentProblemDetailScreen(
                                            problem: item, readOnly: true),
                                  ),
                                );
                              },
                              // 매칭 대기(PENDING)인 질문만 삭제 가능 — 3개 제한 슬롯을 비울 수 있게.
                              onDelete: item.status == 'PENDING'
                                  ? () => _confirmDelete(
                                      context, ref, item.problemId)
                                  : null,
                              // 만료된 질문은 '다시 요청'으로 재탐색 시작.
                              onReRequest: item.status == 'EXPIRED'
                                  ? () => _reRequest(
                                      context, ref, item.problemId)
                                  : null,
                            );
                          }),
                          if (i != items.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int problemId) async {
    final ok = await showConfirmDialog(
      context: context,
      title: '질문 삭제',
      message: '이 질문을 삭제할까요? 삭제하면 되돌릴 수 없어요.',
      cancelText: '취소',
      confirmText: '삭제',
      isDanger: true,
    );
    if (!ok) return;
    try {
      await ref.read(problemRepositoryProvider).cancelProblem(problemId);
      ref.invalidate(studentProblemsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('질문을 삭제했어요.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했어요. 잠시 후 다시 시도해 주세요.')),
        );
      }
    }
  }

  /// 만료된 질문을 다시 탐색 대기로(POST /matching/{id}/start → 백엔드가 reopen).
  Future<void> _reRequest(
      BuildContext context, WidgetRef ref, int problemId) async {
    try {
      await MatchingRepository().startMatching(problemId);
      ref.invalidate(studentProblemsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('다시 강사를 찾기 시작했어요. (24시간)')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('다시 요청에 실패했어요. 잠시 후 시도해 주세요.')),
        );
      }
    }
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.shell,
    required this.item,
    required this.onTap,
    this.onDelete,
    this.onReRequest,
  });

  final ShellTheme shell;
  final StudentProblemModel item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onReRequest;

  // 매칭 대기/탐색 중일 때만 지원 강사 수를 노출(현황 정보).
  bool get _showApplicants => item.status == 'PENDING' || item.searching;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: shell.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: shell.cardBorder.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 학생 홈 '내 질문'과 동일한 썸네일.
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
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
                    children: [
                      Row(
                        children: [
                          ProblemSubjectChip(subject: item.subject),
                          const SizedBox(width: 6),
                          ProblemStatusChip(status: item.status),
                          const Spacer(),
                          if (onDelete != null)
                            InkWell(
                              onTap: onDelete,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.delete_outline_rounded,
                                    color: shell.hintColor, size: 18),
                              ),
                            ),
                          Icon(Icons.chevron_right,
                              color: shell.chevronColor, size: 18),
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: shell.titleColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (_showApplicants) ...[
                            Icon(Icons.people_alt_outlined,
                                size: 14, color: shell.hintColor),
                            const SizedBox(width: 4),
                            Text(
                              '지원 강사 ${item.applicantCount}명',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: shell.hintColor,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            _formatDate(item.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: shell.hintColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onReRequest != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onReRequest,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('다시 요청',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  // 컴팩트: 우측 정렬 + 작은 패딩.
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.shellSurfaceDark : Colors.white,
                    foregroundColor:
                        isDark ? AppColors.studentPoint : Colors.black,
                    side: const BorderSide(color: AppColors.studentPoint),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        color: shell.cardBorder.withValues(alpha: 0.3),
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: shell.hintColor, size: 24),
      );

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}.${two(l.month)}.${two(l.day)}';
  }
}

/// 동시 등록 제한(최대 3개) 현황 — 강사 페이지처럼 N/3 + 슬롯 점으로 시각화. 다크모드 대응.
class _ActiveLimitHeader extends StatelessWidget {
  const _ActiveLimitHeader({required this.shell, required this.active});
  final ShellTheme shell;
  final int active;

  static const int _max = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.studentPoint.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined,
              size: 18, color: AppColors.studentPoint),
          const SizedBox(width: 8),
          Text(
            '진행 중인 질문',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: shell.titleColor,
            ),
          ),
          const Spacer(),
          // 슬롯 점(채워진 만큼 특징색).
          for (var i = 0; i < _max; i++)
            Container(
              margin: const EdgeInsets.only(left: 5),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < active
                    ? AppColors.studentPoint
                    : shell.cardBorder.withValues(alpha: 0.6),
              ),
            ),
          const SizedBox(width: 10),
          Text(
            '$active/$_max',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.studentPoint,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.shell,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.embedded = false,
  });

  final ShellTheme shell;
  final IconData icon;
  final String title;
  final String subtitle;

  /// 이미 부모가 스크롤(ListView)을 제공하면 자체 ListView로 감싸지 않는다.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final children = [
      if (!embedded) const SizedBox(height: 120),
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
    ];
    if (embedded) {
      return Column(children: children);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
  }
}
