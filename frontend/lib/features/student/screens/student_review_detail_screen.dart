import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/utils/date_format_util.dart';
import 'package:ieum/features/student/data/student_review_dummy_data.dart';
import 'package:ieum/features/student/providers/student_review_bookmark_provider.dart';
import 'package:ieum/features/student/widgets/student_review_concept_graph.dart';
import 'package:ieum/features/student/widgets/student_review_video_player.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class StudentReviewDetailScreen extends ConsumerStatefulWidget {
  const StudentReviewDetailScreen({
    super.key,
    required this.item,
  });

  final StudentReviewItem item;

  @override
  ConsumerState<StudentReviewDetailScreen> createState() =>
      _StudentReviewDetailScreenState();
}

class _ReviewMemoEntry {
  _ReviewMemoEntry({
    required this.id,
    required this.content,
    required this.updatedAt,
  });

  final String id;
  String content;
  DateTime updatedAt;
}

class _StudentReviewDetailScreenState
    extends ConsumerState<StudentReviewDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _memoBoxHeight = 300.0;

  late final TabController _tabController;
  late List<_ReviewMemoEntry> _memos;

  int _memoPageIndex = 0;
  bool _isEditingMemo = false;
  final _memoEditController = TextEditingController();

  StudentReviewItem get item => widget.item;

  _ReviewMemoEntry? get _currentMemo =>
      _memos.isEmpty ? null : _memos[_memoPageIndex.clamp(0, _memos.length - 1)];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _memos = [
      _ReviewMemoEntry(
        id: 'memo-1',
        content: '',
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memoEditController.dispose();
    super.dispose();
  }

  void _startMemoEdit() {
    final memo = _currentMemo;
    if (memo == null) return;
    _memoEditController.text = memo.content;
    setState(() => _isEditingMemo = true);
  }

  void _saveMemoEdit() {
    final memo = _currentMemo;
    if (memo == null) return;
    setState(() {
      memo.content = _memoEditController.text.trim();
      memo.updatedAt = DateTime.now();
      _isEditingMemo = false;
    });
  }

  void _cancelMemoEdit() {
    setState(() => _isEditingMemo = false);
    _memoEditController.clear();
  }

  void _addMemo() {
    setState(() {
      _memos.add(
        _ReviewMemoEntry(
          id: 'memo-${DateTime.now().millisecondsSinceEpoch}',
          content: '',
          updatedAt: DateTime.now(),
        ),
      );
      _memoPageIndex = _memos.length - 1;
      _isEditingMemo = true;
      _memoEditController.clear();
    });
  }

  void _deleteMemo() {
    if (_memos.length <= 1) {
      setState(() {
        _memos.first.content = '';
        _memos.first.updatedAt = DateTime.now();
        _isEditingMemo = false;
        _memoEditController.clear();
      });
      return;
    }
    setState(() {
      _memos.removeAt(_memoPageIndex);
      _memoPageIndex = _memoPageIndex.clamp(0, _memos.length - 1);
      _isEditingMemo = false;
      _memoEditController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final pageBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(shell),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(child: _buildVideoSection(shell)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ReviewTabBarDelegate(
                        tabController: _tabController,
                        backgroundColor: pageBg,
                        indicatorColor: AppColors.studentInk,
                        labelColor: shell.titleColor,
                        unselectedColor: shell.hintColor,
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(shell),
                    _buildConceptTab(shell),
                    _buildMemoTab(shell),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ShellTheme shell) {
    final isBookmarked =
        ref.watch(studentReviewBookmarksProvider).contains(item.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: shell.titleColor),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => ref
                .read(studentReviewBookmarksProvider.notifier)
                .toggle(item.id),
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppColors.reviewHighlight : shell.titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(ShellTheme shell) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TutorSubjectBadge(subject: item.subject),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.recordedAtLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: shell.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: shell.titleColor,
            ),
          ),
          const SizedBox(height: 12),
          StudentReviewVideoPlayer(
            durationSeconds: item.videoDurationSeconds,
            initialPositionSeconds: item.initialPositionSeconds,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(ShellTheme shell) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildContentSection(
          shell: shell,
          title: '어떤 문제를 물었나요?',
          body: item.summaryProblem,
        ),
        const SizedBox(height: 12),
        _buildContentSection(
          shell: shell,
          title: '어떻게 풀이했나요?',
          body: item.summarySolution,
        ),
      ],
    );
  }

  Widget _buildConceptTab(ShellTheme shell) {
    final concept = item.conceptDetail;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: shell.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: shell.cardBorder.withValues(alpha: 0.75)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 16,
                    color: shell.subtitleColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI 개념 정리',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: shell.titleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                concept.intro,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: shell.titleColor,
                ),
              ),
            ],
          ),
        ),
        if (concept.graph != null) ...[
          const SizedBox(height: 14),
          StudentReviewConceptGraphCard(
            graph: concept.graph!,
            shell: shell,
          ),
        ],
        const SizedBox(height: 14),
        for (var i = 0; i < concept.sections.length; i++) ...[
          _buildConceptSectionCard(shell, concept.sections[i], i + 1),
          if (i < concept.sections.length - 1) const SizedBox(height: 10),
        ],
        if (concept.relatedTips.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildRelatedTipsCard(shell, concept.relatedTips),
        ],
      ],
    );
  }

  Widget _buildRelatedTipsCard(ShellTheme shell, List<String> tips) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = AppColors.reviewHighlight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder.withValues(alpha: 0.75)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '함께 알아두면 좋아요',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: shell.titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: accent, width: 3),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < tips.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i < tips.length - 1 ? 8 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tips[i],
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: shell.titleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptSectionCard(
    ShellTheme shell,
    StudentReviewConceptSection section,
    int index,
  ) {
    return _buildConceptCard(
      shell: shell,
      leading: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.studentPoint.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Text(
          '$index',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.studentInk,
          ),
        ),
      ),
      title: section.title,
      body: section.body,
      bullets: section.bullets,
      bulletColor: AppColors.studentInk,
    );
  }

  Widget _buildConceptCard({
    required ShellTheme shell,
    required Widget leading,
    required String title,
    String? body,
    required List<String> bullets,
    required Color bulletColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder.withValues(alpha: 0.75)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: shell.titleColor,
                  ),
                ),
              ),
            ],
          ),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: shell.subtitleColor,
              ),
            ),
          ],
          if (bullets.isNotEmpty) ...[
            SizedBox(height: body != null && body.isNotEmpty ? 12 : 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: shell.detailBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < bullets.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i < bullets.length - 1 ? 8 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: bulletColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bullets[i],
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: shell.titleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemoTab(ShellTheme shell) {
    final memo = _currentMemo;
    final isEmpty = memo == null || memo.content.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: shell.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: shell.cardBorder.withValues(alpha: 0.7)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                      color: shell.hintColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '메모',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: shell.subtitleColor,
                      ),
                    ),
                    const Spacer(),
                    if (_memos.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: shell.detailBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MemoPageButton(
                              icon: Icons.chevron_left_rounded,
                              enabled: _memoPageIndex > 0,
                              onTap: () => setState(() {
                                _memoPageIndex--;
                                _isEditingMemo = false;
                              }),
                            ),
                            Text(
                              '${_memoPageIndex + 1}/${_memos.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: shell.subtitleColor,
                              ),
                            ),
                            _MemoPageButton(
                              icon: Icons.chevron_right_rounded,
                              enabled: _memoPageIndex < _memos.length - 1,
                              onTap: () => setState(() {
                                _memoPageIndex++;
                                _isEditingMemo = false;
                              }),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: GestureDetector(
                  onTap: !_isEditingMemo ? _startMemoEdit : null,
                  child: Container(
                    height: _memoBoxHeight,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? shell.detailBackground
                          : const Color(0xFFFAFBFE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isEditingMemo
                            ? shell.cardBorder
                            : shell.cardBorder.withValues(alpha: 0.55),
                      ),
                    ),
                    child: _isEditingMemo
                        ? Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: const InputDecorationTheme(
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: shell.titleColor,
                                selectionColor:
                                    shell.cardBorder.withValues(alpha: 0.45),
                                selectionHandleColor: shell.subtitleColor,
                              ),
                            ),
                            child: TextField(
                              controller: _memoEditController,
                              autofocus: true,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: shell.titleColor,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    '수업 내용, 헷갈린 점, 복습할 키워드를 적어 보세요',
                                hintStyle: TextStyle(
                                  color: shell.hintColor,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          )
                        : isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 36,
                                    color: shell.hintColor.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '탭해서 메모 작성',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: shell.hintColor,
                                    ),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Text(
                                  memo.content,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.65,
                                    color: shell.titleColor,
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
              if (memo != null &&
                  !_isEditingMemo &&
                  memo.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatDotDateTime(memo.updatedAt),
                      style: TextStyle(fontSize: 11, color: shell.hintColor),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: shell.cardBorder.withValues(alpha: 0.6)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: _isEditingMemo
                    ? Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _cancelMemoEdit,
                              child: Text(
                                '취소',
                                style: TextStyle(color: shell.hintColor),
                              ),
                            ),
                          ),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saveMemoEdit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.studentPoint,
                                foregroundColor: AppColors.studentInk,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('저장'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _MemoToolbarButton(
                            icon: Icons.add_rounded,
                            label: '새 메모',
                            labelColor: AppColors.vividBlue,
                            onTap: _addMemo,
                          ),
                          _MemoToolbarDivider(color: shell.cardBorder),
                          _MemoToolbarButton(
                            icon: Icons.edit_outlined,
                            label: '수정',
                            onTap: memo == null ? null : _startMemoEdit,
                          ),
                          _MemoToolbarDivider(color: shell.cardBorder),
                          _MemoToolbarButton(
                            icon: Icons.delete_outline_rounded,
                            label: '삭제',
                            labelColor: AppColors.logoutRed,
                            onTap: _deleteMemo,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection({
    required ShellTheme shell,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.detailBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.studentInk,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: shell.titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoPageButton extends StatelessWidget {
  const _MemoPageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? shell.subtitleColor : shell.hintColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _MemoToolbarButton extends StatelessWidget {
  const _MemoToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final color = onTap == null
        ? shell.hintColor.withValues(alpha: 0.4)
        : (labelColor ?? shell.titleColor);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoToolbarDivider extends StatelessWidget {
  const _MemoToolbarDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: color.withValues(alpha: 0.6),
    );
  }
}

class _ReviewTabBarDelegate extends SliverPersistentHeaderDelegate {
  _ReviewTabBarDelegate({
    required this.tabController,
    required this.backgroundColor,
    required this.indicatorColor,
    required this.labelColor,
    required this.unselectedColor,
  });

  final TabController tabController;
  final Color backgroundColor;
  final Color indicatorColor;
  final Color labelColor;
  final Color unselectedColor;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: indicatorColor,
        indicatorWeight: 3,
        labelColor: labelColor,
        unselectedLabelColor: unselectedColor,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        dividerColor: Theme.of(context).dividerColor,
        tabs: const [
          Tab(text: '요약'),
          Tab(text: '개념정리'),
          Tab(text: '메모'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ReviewTabBarDelegate oldDelegate) {
    return tabController != oldDelegate.tabController ||
        backgroundColor != oldDelegate.backgroundColor ||
        indicatorColor != oldDelegate.indicatorColor;
  }
}
