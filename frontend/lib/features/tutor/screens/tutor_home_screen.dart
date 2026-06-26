import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/matching/models/searching_problem_model.dart';
import 'package:ieum/features/matching/providers/matching_provider.dart'
    show matchingProvider, tutorApplicationsProvider;
import 'package:ieum/features/tutor/providers/tutor_availability_provider.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_problem_image.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen> {
  static const int _pageSize = 5;

  int _questionPageIndex = 0;
  final Set<int> _rejectedProblemIds = {};

  List<SearchingProblemModel> _pagedProblems(
      List<SearchingProblemModel> visible) {
    if (visible.isEmpty) return [];
    final pageCount = (visible.length / _pageSize).ceil();
    final safeIndex = _questionPageIndex.clamp(0, pageCount - 1);
    final start = safeIndex * _pageSize;
    final end = (start + _pageSize).clamp(0, visible.length);
    return visible.sublist(start, end);
  }

  int _pageCount(int visibleCount) {
    if (visibleCount == 0) return 0;
    return (visibleCount / _pageSize).ceil();
  }

  Future<void> _navigateToDetail(SearchingProblemModel problem) async {
    final rejected =
        await context.push<int?>('/problem-detail', extra: problem);
    if (!mounted) return;
    if (rejected != null) {
      setState(() => _rejectedProblemIds.add(rejected));
    } else {
      ref.invalidate(tutorApplicationsProvider);
    }
  }

  String _timeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final matchingState = ref.watch(matchingProvider);

    final visibleList = matchingState.problems.whenOrNull(
          data: (list) => list
              .where((p) => !_rejectedProblemIds.contains(p.problemId))
              .toList(),
        ) ??
        [];

    return Scaffold(
      backgroundColor: shell.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          // STOMP 실시간이 누락돼도 당겨서 새 질문을 받아올 수 있게(재로그인 불필요)
          color: AppColors.primaryBlue,
          onRefresh: () => ref.read(matchingProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '강사 홈',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: shell.titleColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildOnlineStatusCard(),
              const SizedBox(height: 24),
              _buildQuestionListHeader(visibleList.length),
              const SizedBox(height: 12),
              matchingState.problems.when(
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                error: (_, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '불러오기에 실패했습니다.',
                          style: TextStyle(
                            color: shell.hintColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              ref.read(matchingProvider.notifier).refresh(),
                          child: const Text(
                            '다시 시도',
                            style: TextStyle(color: AppColors.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (_) {
                  if (visibleList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          _rejectedProblemIds.isNotEmpty
                              ? '표시할 새 질문이 없습니다.'
                              : '탐색 중인 질문이 없습니다.',
                          style:
                              TextStyle(color: shell.hintColor, fontSize: 14),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final problem in _pagedProblems(visibleList)) ...[
                        _buildQuestionCard(problem),
                        const SizedBox(height: 12),
                      ],
                      _buildQuestionPagination(visibleList.length),
                    ],
                  );
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatusCard() {
    final shell = ShellTheme.of(context);
    final isOnline = ref.watch(tutorAvailabilityProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '온라인 상태',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnline ? '질문을 기다리고 있어요' : '오프라인 상태입니다',
                      style: TextStyle(fontSize: 13, color: shell.hintColor),
                    ),
                  ],
                ),
              ),
              SwitchTheme(
                data: SwitchThemeData(
                  thumbIcon: WidgetStateProperty.all(
                    Icon(
                      Icons.circle,
                      size: 22,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? shell.iconBackground
                          : Colors.white,
                      fill: 1,
                    ),
                  ),
                  thumbColor: WidgetStateProperty.all(Colors.transparent),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AppColors.primaryBlue
                        : shell.trackOffColor;
                  }),
                  trackOutlineColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                ),
                child: Switch(
                  value: isOnline,
                  onChanged: (value) =>
                      ref.read(tutorAvailabilityProvider.notifier).toggle(value),
                ),
              ),
            ],
          ),
          if (isOnline) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: shell.dividerColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '접속 중',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionListHeader(int count) {
    final shell = ShellTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            '새로운 질문 리스트',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: shell.titleColor,
            ),
          ),
        ),
        Text(
          '$count개',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionPagination(int visibleCount) {
    final shell = ShellTheme.of(context);
    final pageCount = _pageCount(visibleCount);
    if (pageCount <= 1) return const SizedBox.shrink();

    final safeIndex = _questionPageIndex.clamp(0, pageCount - 1);
    final canGoPrev = safeIndex > 0;
    final canGoNext = safeIndex < pageCount - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: canGoPrev
                ? () => setState(() => _questionPageIndex -= 1)
                : null,
            icon: Icon(
              Icons.chevron_left,
              size: 22,
              color: canGoPrev ? shell.titleColor : shell.hintColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            '${safeIndex + 1} / $pageCount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: shell.titleColor,
            ),
          ),
          IconButton(
            onPressed: canGoNext
                ? () => setState(() => _questionPageIndex += 1)
                : null,
            icon: Icon(
              Icons.chevron_right,
              size: 22,
              color: canGoNext ? shell.titleColor : shell.hintColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(SearchingProblemModel problem) {
    final shell = ShellTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TutorRequestProblemThumbnail(
                imageUrl: problem.imageUrls.firstOrNull,
                title: _cardTitle(problem),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 과목 · 대분류 · 소분류 → 키워드 칩으로
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        TutorSubjectBadge(subject: problem.subjectLabel),
                        if ((problem.primaryType ?? '').isNotEmpty)
                          _keywordChip(problem.primaryType!, shell),
                        if ((problem.secondaryType ?? '').isNotEmpty)
                          _keywordChip(problem.secondaryType!, shell),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 본문 = 문제 요약(summary)
                    Text(
                      (problem.summary?.trim().isNotEmpty ?? false)
                          ? problem.summary!.trim()
                          : '문제 요약 없음',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: shell.titleColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 부가 = 학생이 입력한 설명(description) — 있을 때만
                    if ((problem.studentDescription ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        problem.studentDescription!.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color: shell.hintColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(problem.createdAt),
                      style: TextStyle(fontSize: 11, color: shell.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActionButtons(problem),
        ],
      ),
    );
  }

  String _cardTitle(SearchingProblemModel problem) {
    final primary = problem.primaryType ?? '';
    final secondary = problem.secondaryType ?? '';
    if (primary.isEmpty) return secondary;
    if (secondary.isEmpty) return primary;
    return '$primary · $secondary';
  }

  /// 대분류·소분류 키워드 칩 (과목 뱃지와 함께 Wrap에 나열).
  Widget _keywordChip(String text, ShellTheme shell) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: shell.hintColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: shell.titleColor,
        ),
      ),
    );
  }

  Widget _buildActionButtons(SearchingProblemModel problem) {
    // 목록 카드에서는 '자세히'만. 신청은 상세화면에서 문제를 확인한 뒤 하도록 한다.
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => _navigateToDetail(problem),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.onPrimaryFill(Theme.of(context).brightness),
          elevation: 0,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '자세히',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
