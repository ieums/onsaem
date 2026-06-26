import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/api_error.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/models/review_lesson_item.dart';
import 'package:ieum/features/student/providers/lesson_review_provider.dart';
import 'package:ieum/features/student/screens/student_review_detail_screen.dart';

class StudentLessonsScreen extends ConsumerStatefulWidget {
  const StudentLessonsScreen({super.key});

  @override
  ConsumerState<StudentLessonsScreen> createState() =>
      _StudentLessonsScreenState();
}

class _StudentLessonsScreenState
    extends ConsumerState<StudentLessonsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReviewLessonItem> _filter(List<ReviewLessonItem> lessons) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return lessons;
    return lessons
        .where((l) => l.title.toLowerCase().contains(query))
        .toList();
  }

  void _openDetail(ReviewLessonItem lesson) {
    // 준비중(전사 미완료)인 강의는 진입 불가 — 진입 시 세션 생성이 막혀 에러가 남.
    if (!lesson.ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복습 준비중이에요. 잠시 후 다시 확인해주세요.')),
      );
      return;
    }
    final theme = Theme.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: theme,
          child: StudentReviewDetailScreen(
            lessonId: lesson.lessonId,
            title: lesson.title,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final lessonsAsync = ref.watch(reviewLessonsProvider);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
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
            const SizedBox(height: 16),
            Expanded(
              child: lessonsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        apiErrorMessage(e),
                        style: TextStyle(
                            color: shell.hintColor, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(reviewLessonsProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
                data: (lessons) {
                  final items = _filter(lessons);
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        '복습 내역이 없습니다.',
                        style: TextStyle(
                            color: shell.hintColor, fontSize: 14),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(reviewLessonsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, index) => _ReviewLessonCard(
                        lesson: items[index],
                        onTap: () => _openDetail(items[index]),
                      ),
                    ),
                  );
                },
              ),
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
      onChanged: (_) => setState(() {}),
      style: TextStyle(fontSize: 15, color: shell.titleColor),
      decoration: InputDecoration(
        hintText: '강의명으로 검색',
        hintStyle: TextStyle(color: shell.hintColor, fontSize: 14),
        filled: true,
        fillColor:
            isDark ? shell.detailBackground : shell.cardBackground,
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
          borderSide: const BorderSide(
              color: AppColors.studentPoint, width: 1.5),
        ),
        suffixIcon: Icon(Icons.search_rounded, color: shell.hintColor),
      ),
    );
  }
}

class _ReviewLessonCard extends StatelessWidget {
  const _ReviewLessonCard({required this.lesson, required this.onTap});

  final ReviewLessonItem lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ready = lesson.ready;

    // ready=준비완료(녹색 계열), 준비중=회색 계열
    final badgeColor = ready
        ? (isDark ? const Color(0xFF2E3D1E) : const Color(0xFFF1FCE0))
        : (isDark ? const Color(0xFF2A2E36) : const Color(0xFFEFEFEF));
    final badgeTextColor = ready
        ? (isDark ? const Color(0xFFB6E26A) : AppColors.studentInk)
        : (isDark ? const Color(0xFFAAB0BA) : const Color(0xFF8A8F99));

    return Opacity(
      opacity: ready ? 1.0 : 0.7,
      child: Material(
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: shell.titleColor,
                        ),
                      ),
                      if (lesson.endedAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(lesson.endedAt!),
                          style: TextStyle(
                              fontSize: 13, color: shell.hintColor),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ready ? '복습 시작' : '복습 준비중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}