import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/tutor/providers/tutor_availability_provider.dart';
import 'package:ieum/features/tutor/data/tutor_request_list_dummy_data.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_accept_dialog.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_problem_image.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen> {
  int _questionPageIndex = 0;
  final Set<String> _rejectedQuestionIds = {};

  List<TutorRequestListItem> get _allRecentQuestions =>
      TutorRequestDummyData.recentQuestions();

  List<TutorRequestListItem> get _visibleRecentQuestions {
    return _allRecentQuestions
        .where((q) => !_rejectedQuestionIds.contains(q.id))
        .toList();
  }

  void _rejectQuestion(TutorRequestListItem item) {
    setState(() {
      _rejectedQuestionIds.add(item.id);
      final pageCount = _questionPageCount;
      if (pageCount == 0) {
        _questionPageIndex = 0;
      } else if (_questionPageIndex >= pageCount) {
        _questionPageIndex = pageCount - 1;
      }
    });
  }

  int get _questionPageCount {
    final count = _visibleRecentQuestions.length;
    if (count == 0) return 0;
    return (count / TutorRequestDummyData.newQuestionPageSize).ceil();
  }

  List<TutorRequestListItem> get _pagedQuestions {
    final items = _visibleRecentQuestions;
    if (items.isEmpty) return [];

    final pageCount = _questionPageCount;
    final safeIndex =
        pageCount == 0 ? 0 : _questionPageIndex.clamp(0, pageCount - 1);
    final start = safeIndex * TutorRequestDummyData.newQuestionPageSize;
    final end = (start + TutorRequestDummyData.newQuestionPageSize)
        .clamp(0, items.length);
    return items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return Scaffold(
      backgroundColor: shell.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
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
              _buildQuestionListHeader(),
              const SizedBox(height: 12),
              if (_visibleRecentQuestions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      _rejectedQuestionIds.isNotEmpty
                          ? '표시할 새 질문이 없습니다.'
                          : '5분 이내 새 질문이 없습니다.',
                      style: TextStyle(color: shell.hintColor, fontSize: 14),
                    ),
                  ),
                )
              else ...[
                for (final question in _pagedQuestions) ...[
                  _buildQuestionCard(question),
                  const SizedBox(height: 12),
                ],
                _buildQuestionPagination(),
              ],
            ],
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
                      style: TextStyle(
                        fontSize: 13,
                        color: shell.hintColor,
                      ),
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
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Switch(
                  value: isOnline,
                  onChanged: (value) =>
                      ref.read(tutorAvailabilityProvider.notifier).state =
                          value,
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

  Widget _buildQuestionListHeader() {
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
          '${_visibleRecentQuestions.length}개',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionPagination() {
    final shell = ShellTheme.of(context);
    final pageCount = _questionPageCount;
    if (pageCount <= 1) return const SizedBox.shrink();

    final canGoPrev = _questionPageIndex > 0;
    final canGoNext = _questionPageIndex < pageCount - 1;

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
            '${_questionPageIndex + 1} / $pageCount',
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

  Widget _buildQuestionCard(TutorRequestListItem question) {
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
              TutorRequestProblemThumbnail(item: question),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TutorSubjectBadge(subject: question.subject),
                    const SizedBox(height: 8),
                    Text(
                      question.detailSubject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: shell.titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (question.chapter.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        question.chapter,
                        style: TextStyle(
                          fontSize: 13,
                          color: shell.hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      question.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: shell.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActionButtons(question),
        ],
      ),
    );
  }

  Future<void> _showAcceptConfirmDialog(TutorRequestListItem item) async {
    final confirmed = await showTutorRequestAcceptDialog(context, item);
    if (!mounted || confirmed != true) return;
  }

  Widget _buildActionButtons(TutorRequestListItem question) {
    final shell = ShellTheme.of(context);
    final isOnline = ref.watch(tutorAvailabilityProvider);
    final acceptBg = isOnline ? AppColors.primaryBlue : shell.offlineButtonColor;
    final acceptFg = isOnline
        ? AppColors.onPrimaryFill(Theme.of(context).brightness)
        : shell.offlineButtonTextColor;
    final rejectBorder = isOnline ? shell.borderColor : shell.offlineButtonColor;
    final rejectFg = isOnline ? shell.titleColor : shell.offlineButtonTextColor;

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: isOnline ? () => _showAcceptConfirmDialog(question) : null,
            style: FilledButton.styleFrom(
              backgroundColor: acceptBg,
              foregroundColor: acceptFg,
              elevation: 0,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '수락',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: isOnline ? () => _rejectQuestion(question) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: rejectFg,
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: rejectBorder, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '거절',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
