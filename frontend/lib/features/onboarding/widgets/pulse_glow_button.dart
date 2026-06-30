import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'onboarding_tokens.dart';

/// 펄스 글로우 CTA 버튼.
///
/// HTML `@keyframes btnPulse`: box-shadow blur 30↔44, 알파 0.35↔0.6, 2.4s 무한.
/// `:active`에서 scale(0.97). flutter_animate가 BoxShadow를 직접 못 다루므로
/// `.custom`으로 blur/alpha를 lerp 한다.
class PulseGlowButton extends StatefulWidget {
  const PulseGlowButton({
    super.key,
    required this.label,
    required this.color,
    this.labelColor,
    this.onTap,
  });

  final String label;
  final Color color;

  /// 라벨 글자색(포인트 위). null이면 현재 팔레트 [OnbPalette.bg]로 폴백(다크 보존).
  final Color? labelColor;

  final VoidCallback? onTap;

  @override
  State<PulseGlowButton> createState() => _PulseGlowButtonState();
}

class _PulseGlowButtonState extends State<PulseGlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final labelColor = widget.labelColor ?? OnbPalette.of(context).bg;
    final btn = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: labelColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.16, // -0.01em
          ),
        ),
      ),
    );

    final glowing = btn.animate(onPlay: (c) => c.repeat(reverse: true)).custom(
          duration: 1200.ms, // 2.4s 왕복
          curve: Curves.easeInOut,
          builder: (context, v, child) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: lerpDouble(0.35, 0.6, v)!),
                  blurRadius: lerpDouble(30, 44, v)!,
                ),
              ],
            ),
            child: child,
          ),
        );

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: glowing,
    );
  }
}
