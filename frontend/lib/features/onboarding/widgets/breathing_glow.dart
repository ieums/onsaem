import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 숨쉬는 radial glow.
///
/// HTML `@keyframes breathe`: opacity 0.6↔1, scale 1↔1.15, 4s ease-in-out 무한.
/// deluxe 글로우는 `filter:blur` 없이 radial-gradient만 쓰므로 [RadialGradient]로 일치.
class BreathingGlow extends StatelessWidget {
  const BreathingGlow({
    super.key,
    required this.size,
    required this.color,
    this.maxAlpha = 0.22, // 중심 알파 (HTML rgba(...,0.22))
    this.stop = 0.65, // 65%에서 투명
  });

  final double size;
  final Color color;
  final double maxAlpha;
  final double stop;

  @override
  Widget build(BuildContext context) {
    final glow = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: maxAlpha), color.withValues(alpha: 0)],
          stops: [0.0, stop],
        ),
      ),
    );

    return glow
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.15, duration: 2000.ms, curve: Curves.easeInOut)
        .fade(begin: 0.6, end: 1.0, duration: 2000.ms, curve: Curves.easeInOut);
  }
}
