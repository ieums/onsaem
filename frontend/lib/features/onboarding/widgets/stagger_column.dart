import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'onboarding_tokens.dart';

/// 위에서 떨어지듯 하나씩 등장하는 스태거 리스트.
///
/// HTML `@keyframes dropIn`: translateY(-16px)→0 + opacity, 0.6s 토스 커브.
/// nth-child 1 = 0.15s, 2 = 0.30s ... ([base] + [step]*i).
/// [revealed]가 true가 되면 재생.
class StaggerColumn extends StatelessWidget {
  const StaggerColumn({
    super.key,
    required this.children,
    required this.revealed,
    this.gap = 12,
    this.beginY = -16,
    this.base = const Duration(milliseconds: 150),
    this.step = const Duration(milliseconds: 150),
  });

  final List<Widget> children;
  final bool revealed;
  final double gap;
  final double beginY;
  final Duration base;
  final Duration step;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(SizedBox(height: gap));
      final delay = base + step * i;
      items.add(
        children[i]
            .animate(target: revealed ? 1 : 0)
            .fadeIn(duration: OnbDur.drop, delay: delay, curve: onbToss)
            .moveY(begin: beginY, end: 0, duration: OnbDur.drop, delay: delay, curve: onbToss),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items);
  }
}
