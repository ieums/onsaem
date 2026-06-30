import 'package:flutter/material.dart';

/// 숫자 카운트업 텍스트.
///
/// HTML: `0 → target`, easeOutCubic, 1.4s, `toLocaleString('ko-KR') + '원'`.
/// [active]가 false→true로 바뀌는 순간 0부터 [target]까지 한 번 카운트한다.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.target,
    required this.active,
    this.duration = const Duration(milliseconds: 1400),
    this.suffix = '원',
    this.style,
  });

  final int target;
  final bool active;
  final Duration duration;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: active ? 1 : 0),
      duration: duration,
      curve: Curves.easeOutCubic, // HTML: 1 - pow(1-p, 3)
      builder: (context, t, _) {
        final value = (t * target).floor();
        return Text('${_comma(value)}$suffix', style: style);
      },
    );
  }

  /// 천 단위 콤마 (ko-KR toLocaleString 대응)
  static String _comma(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
