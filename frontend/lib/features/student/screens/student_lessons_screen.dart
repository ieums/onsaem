import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/utils/list_pagination.dart';
import 'package:ieum/core/widgets/list_pagination_controls.dart';
import 'package:ieum/features/student/data/student_review_dummy_data.dart';
import 'package:ieum/features/student/providers/student_review_bookmark_provider.dart';
import 'package:ieum/features/student/screens/student_review_detail_screen.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class StudentLessonsScreen extends ConsumerStatefulWidget {
  const StudentLessonsScreen({super.key});

  @override
  ConsumerState<StudentLessonsScreen> createState() =>
      _StudentLessonsScreenState();
}

class _StudentLessonsScreenState extends ConsumerState<StudentLessonsScreen> {
  final _searchController = TextEditingController();
  String _selectedSubject = '전체';
  bool _bookmarksOnly = false;
  int _pageIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentReviewItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    final bookmarkedIds = ref.watch(studentReviewBookmarksProvider);

    return StudentReviewDummyData.items.where((item) {
      if (_bookmarksOnly && !bookmarkedIds.contains(item.id)) return false;

      final subjectOk =
          _selectedSubject == '전체' || item.subject == _selectedSubject;
      if (!subjectOk) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.tutorName.toLowerCase().contains(query) ||
          item.subject.toLowerCase().contains(query);
    }).toList();
  }

  int get _pageCount => ListPagination.pageCount(
        _visibleItems.length,
        StudentReviewDummyData.listPageSize,
      );

  int get _safePageIndex =>
      ListPagination.clampPageIndex(_pageIndex, _pageCount);

  List<StudentReviewItem> get _pagedItems => ListPagination.slice(
        _visibleItems,
        pageIndex: _safePageIndex,
        pageSize: StudentReviewDummyData.listPageSize,
      );

  void _resetPage() => setState(() => _pageIndex = 0);

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final pageBg = Theme.of(context).scaffoldBackgroundColor;
    final items = _pagedItems;
    final totalCount = _visibleItems.length;

    return ColoredBox(
      color: pageBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                '복습 목록',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: shell.titleColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSearchField(shell),
            ),
            const SizedBox(height: 14),
            _buildSubjectFilters(shell),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _bookmarksOnly ? '북마크 $totalCount개' : '전체 $totalCount개',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: shell.subtitleColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: totalCount == 0
                  ? Center(
                      child: Text(
                        _bookmarksOnly
                            ? '북마크한 복습이 없습니다.'
                            : '표시할 복습이 없습니다.',
                        style: TextStyle(color: shell.hintColor, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isBookmarked = ref
                            .watch(studentReviewBookmarksProvider)
                            .contains(item.id);
                        return _ReviewListCard(
                          item: item,
                          isBookmarked: isBookmarked,
                          onTap: () => _openDetail(item),
                        );
                      },
                    ),
            ),
            ListPaginationControls(
              pageIndex: _safePageIndex,
              pageCount: _pageCount,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              onPrevious: () =>
                  setState(() => _pageIndex = _safePageIndex - 1),
              onNext: () => setState(() => _pageIndex = _safePageIndex + 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ShellTheme shell) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _searchController,
      onChanged: (_) => _resetPage(),
      style: TextStyle(fontSize: 15, color: shell.titleColor),
      decoration: InputDecoration(
        hintText: '검색어를 입력하세요',
        hintStyle: TextStyle(color: shell.hintColor, fontSize: 14),
        filled: true,
        fillColor: isDark ? shell.detailBackground : shell.cardBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: shell.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: shell.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.studentPoint, width: 1.5),
        ),
        suffixIcon: Icon(Icons.search_rounded, color: shell.hintColor),
      ),
    );
  }

  Widget _buildSubjectFilters(ShellTheme shell) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: StudentReviewDummyData.subjectFilters.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip(
              shell: shell,
              primary: primary,
              label: '북마크',
              selected: _bookmarksOnly,
              leading: Icon(
                _bookmarksOnly
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 16,
                color: _bookmarksOnly
                    ? AppColors.onPrimaryFill(Theme.of(context).brightness)
                    : shell.subtitleColor,
              ),
              onTap: () => setState(() {
                _bookmarksOnly = !_bookmarksOnly;
                _pageIndex = 0;
              }),
            );
          }

          final label = StudentReviewDummyData.subjectFilters[index - 1];
          final selected = _selectedSubject == label;
          return _buildFilterChip(
            shell: shell,
            primary: primary,
            label: label,
            selected: selected,
            onTap: () => setState(() {
              _selectedSubject = label;
              _pageIndex = 0;
            }),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required ShellTheme shell,
    required Color primary,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? leading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary : shell.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary : shell.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.onPrimaryFill(Theme.of(context).brightness)
                    : shell.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(StudentReviewItem item) {
    final theme = Theme.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: theme,
          child: StudentReviewDetailScreen(item: item),
        ),
      ),
    );
  }
}

class _ReviewListCard extends StatelessWidget {
  const _ReviewListCard({
    required this.item,
    required this.isBookmarked,
    required this.onTap,
  });

  static const _bookmarkActiveColor = Color(0xFFF5A623);

  final StudentReviewItem item;
  final bool isBookmarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reviewingText =
        isDark ? const Color(0xFFFFC48A) : const Color(0xFFE89A56);
    final reviewingBg =
        isDark ? const Color(0xFF4A3828) : const Color(0xFFFFF4E8);

    return Material(
      color: shell.cardBackground,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: shell.cardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TutorSubjectBadge(subject: item.subject),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.recordedAtLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: shell.hintColor,
                      ),
                    ),
                  ),
                  Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 22,
                    color: isBookmarked
                        ? _bookmarkActiveColor
                        : shell.hintColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: 18,
                    color: shell.subtitleColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.tutorName} 강사 · ${item.videoDurationLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: shell.subtitleColor,
                      ),
                    ),
                  ),
                  if (item.showReviewingBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: reviewingBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '복습중',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: reviewingText,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
