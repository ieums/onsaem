import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/api_error.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/models/lesson_review_session.dart';
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

  List<LessonReviewSession> _filter(List<LessonReviewSession> sessions) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return sessions;
    return sessions
        .where((s) => s.title.toLowerCase().contains(query))
        .toList();
  }

  void _openDetail(LessonReviewSession session) {
    final theme = Theme.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: theme,
          child: StudentReviewDetailScreen(session: session),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final sessionsAsync = ref.watch(lessonReviewSessionsProvider);

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
              child: sessionsAsync.when(
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
                            ref.invalidate(lessonReviewSessionsProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
                data: (sessions) {
                  final items = _filter(sessions);
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        '복습 내역이 없습니다.',
                        style: TextStyle(
                            color: shell.hintColor, fontSize: 14),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, index) => _SessionCard(
                      session: items[index],
                      onTap: () => _openDetail(items[index]),
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
          borderSide:
              const BorderSide(color: AppColors.studentInk, width: 1.5),
          borderSide: const BorderSide(
              color: AppColors.studentPoint, width: 1.5),
        ),
        suffixIcon: Icon(Icons.search_rounded, color: shell.hintColor),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final LessonReviewSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = !session.status.isClosed;

    final badgeColor = isActive
        ? (isDark ? const Color(0xFF4A3828) : const Color(0xFFFFF4E8))
        : (isDark ? const Color(0xFF1E2A3A) : const Color(0xFFEEF4FF));
    final badgeTextColor = isActive
        ? (isDark ? const Color(0xFFFFC48A) : const Color(0xFFE89A56))
        : (isDark ? const Color(0xFF8AB4F8) : const Color(0xFF3D7EF5));

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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(session.createdAt),
                      style: TextStyle(
                          fontSize: 13, color: shell.hintColor),
                    ),
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
                  isActive ? '복습중' : '완료',
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
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}