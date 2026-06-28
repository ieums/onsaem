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
          isDark ? AppColors.shellScaffoldDark : AppColors.tutorScaffoldLight,
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
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _ReviewSummary(shell: shell, profile: profile),
                      const SizedBox(height: 8),
                      Divider(
                          color: shell.cardBorder.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      for (var i = 0; i < profile.reviews.length; i++) ...[
                        _card(shell, profile.reviews[i]),
                        if (i != profile.reviews.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
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

/// 별점 요약 — 왼쪽 평균(큰 숫자+별), 오른쪽 점수별 분포 막대. (제공된 디자인 기준)
class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.shell, required this.profile});
  final ShellTheme shell;
  final TutorProfileDetail profile;

  static const _star = Color(0xFFFFB400); // 별/막대 색

  @override
  Widget build(BuildContext context) {
    final reviews = profile.reviews;
    // 점수별 개수(5→1). reviews 목록으로 분포 계산.
    final counts = <int, int>{for (var s = 1; s <= 5; s++) s: 0};
    for (final r in reviews) {
      final s = r.rating.clamp(1, 5);
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final total = profile.reviewCount > 0 ? profile.reviewCount : reviews.length;
    final maxCount =
        counts.values.fold<int>(0, (m, c) => c > m ? c : m).clamp(1, 1 << 30);
    final avg = profile.ratingAvg ??
        (reviews.isEmpty
            ? 0
            : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length);

    return Column(
      children: [
        // 총 리뷰수
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('총 리뷰수 ',
                style: TextStyle(fontSize: 15, color: shell.hintColor)),
            Text('$total',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 왼쪽: 평균 + 별
            Column(
              children: [
                Text('평균',
                    style: TextStyle(fontSize: 13, color: shell.hintColor)),
                const SizedBox(height: 2),
                Text(
                  (avg as num).toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: shell.titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                _FractionalStars(value: avg.toDouble(), size: 18),
              ],
            ),
            const SizedBox(width: 24),
            // 오른쪽: 점수별 막대
            Expanded(
              child: Column(
                children: [
                  for (var s = 5; s >= 1; s--) ...[
                    _bar(s, counts[s] ?? 0, maxCount),
                    if (s != 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bar(int score, int count, int maxCount) {
    final frac = (count / maxCount).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text('$score점',
              style: TextStyle(fontSize: 12.5, color: shell.titleColor)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                    height: 10,
                    color: shell.cardBorder.withValues(alpha: 0.5)),
                FractionallySizedBox(
                  widthFactor: count == 0 ? 0.0 : frac,
                  child: Container(height: 10, color: _star),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12.5, color: shell.hintColor)),
        ),
      ],
    );
  }
}

/// 평균 별점을 소수까지 반영해 부분 채움으로 그린다(예: 4.6 → 별 4.6칸).
class _FractionalStars extends StatelessWidget {
  const _FractionalStars({required this.value, this.size = 18});
  final double value;
  final double size;

  static const _color = Color(0xFFFFB400);

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++)
              Icon(icon, size: size, color: color),
          ],
        );
    final frac = (value / 5).clamp(0.0, 1.0);
    return Stack(
      children: [
        row(Icons.star_rounded, const Color(0xFFE0E0E0)),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: frac,
            child: row(Icons.star_rounded, _color),
          ),
        ),
      ],
    );
  }
}
