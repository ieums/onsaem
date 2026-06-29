import 'package:flutter/material.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/tutor_profile_detail.dart';

/// 별점 요약 — 왼쪽 평균(큰 숫자+별), 오른쪽 점수별 분포 막대.
/// 강사 '받은 리뷰' 화면과 학생이 보는 강사 프로필에서 공용으로 쓴다.
class ReviewSummary extends StatelessWidget {
  const ReviewSummary({super.key, required this.shell, required this.profile});
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
            for (var i = 0; i < 5; i++) Icon(icon, size: size, color: color),
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
