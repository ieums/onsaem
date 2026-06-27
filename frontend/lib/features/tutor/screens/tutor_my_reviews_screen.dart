import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/tutor_profile_repository.dart';
import 'package:ieum/features/student/models/tutor_profile_detail.dart';

class TutorMyReviewsScreen extends ConsumerWidget {
  const TutorMyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final theme =
        (isDark ? AppTheme.shellDark : AppTheme.shellLight).copyWith(
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
    final tutorId = ref.watch(currentUserProvider)?.id;

    return Theme(
      data: theme,
      child: Builder(builder: (context) {
        final shell = ShellTheme.of(context);
        if (tutorId == null) {
          return Scaffold(
            appBar: _appBar(),
            body: Center(
              child: Text('로그인이 필요합니다.',
                  style: TextStyle(color: shell.hintColor)),
            ),
          );
        }
        final async = ref.watch(tutorProfileProvider(tutorId));
        return Scaffold(
          appBar: _appBar(),
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () =>
                  ref.refresh(tutorProfileProvider(tutorId).future),
              child: async.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(
                        color: AppColors.primaryBlue),
                  ),
                ),
                error: (_, _) =>
                    _hint(shell, '리뷰를 불러오지 못했어요.'),
                data: (profile) {
                  if (profile.reviews.isEmpty) {
                    return _hint(shell, '아직 받은 리뷰가 없어요.');
                  }
                  return ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        20, 16, 20, 24),
                    itemCount: profile.reviews.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _card(shell, profile.reviews[i]),
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: const Text('받은 리뷰',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      );

  Widget _hint(ShellTheme shell, String text) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.star_outline_rounded,
              size: 52,
              color: shell.hintColor.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: shell.hintColor)),
        ],
      );

  Widget _card(ShellTheme shell, TutorReviewItem r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: shell.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.studentName ?? '학생',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: shell.titleColor),
              ),
              const SizedBox(width: 8),
              for (var s = 1; s <= 5; s++)
                Icon(
                  s <= r.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: const Color(0xFFF5A623),
                ),
              const Spacer(),
              Text(_ymd(r.createdAt),
                  style: TextStyle(
                      fontSize: 12, color: shell.hintColor)),
            ],
          ),
          if ((r.comment?.trim().isNotEmpty) ?? false) ...[
            const SizedBox(height: 10),
            Text(r.comment!.trim(),
                style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: shell.titleColor)),
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
