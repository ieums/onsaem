import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/mypage_models.dart';
import 'package:ieum/features/student/providers/mypage_provider.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';

/// 내 활동 — 내가 쓴 리뷰 목록. GET /reviews/me
class StudentMyReviewsScreen extends ConsumerWidget {
  const StudentMyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
    final async = ref.watch(myReviewsProvider);

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '내 리뷰 내역',
              onBack: () => Navigator.of(context).pop(),
            ),
            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.studentInk,
                onRefresh: () => ref.refresh(myReviewsProvider.future),
                child: async.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(color: AppColors.studentInk),
                    ),
                  ),
                  error: (_, _) => _hint(shell, '리뷰를 불러오지 못했어요.'),
                  data: (items) {
                    if (items.isEmpty) {
                      return _hint(shell, '아직 작성한 리뷰가 없어요.');
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _card(shell, items[i]),
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

  Widget _hint(ShellTheme shell, String text) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.rate_review_outlined,
              size: 52, color: shell.hintColor.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: shell.hintColor)),
        ],
      );

  Widget _card(ShellTheme shell, MyReview r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var s = 1; s <= 5; s++)
                Icon(
                  s <= r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: const Color(0xFFF5A623),
                ),
              const Spacer(),
              Text(_ymd(r.createdAt),
                  style: TextStyle(fontSize: 12, color: shell.hintColor)),
            ],
          ),
          if ((r.comment?.trim().isNotEmpty) ?? false) ...[
            const SizedBox(height: 10),
            Text(r.comment!.trim(),
                style: TextStyle(
                    fontSize: 14, height: 1.4, color: shell.titleColor)),
          ],
        ],
      ),
    );
  }

  static String _ymd(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}.${two(l.month)}.${two(l.day)}';
  }
}
