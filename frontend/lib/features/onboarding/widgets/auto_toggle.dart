import 'dart:async';

import 'package:flutter/material.dart';

import 'onboarding_tokens.dart';

/// 섹션이 보이면 0.5s 후 스르륵 켜지는 토글 데모 (강사 온라인 켜기).
///
/// HTML: `.toggle-demo.on` 상태로 전환 시
///  - 스위치 bg #3a3a46 → point, 그림자 on
///  - knob translateX(24px), 스프링 cubic-bezier(0.34,1.56,0.64,1), 0.5s
///  - 텍스트색 dim → point, 문구 '● 오프라인' → '● 온라인 — 질문 받는 중'
///  - 우상단 glow opacity 0 → 1
class AutoToggle extends StatefulWidget {
  const AutoToggle({
    super.key,
    required this.revealed,
    required this.color,
    this.title = '실시간 수업',
    this.offText = '● 오프라인',
    this.onText = '● 온라인 — 질문 받는 중',
    this.delay = const Duration(milliseconds: 500),
  });

  final bool revealed;
  final Color color;
  final String title;
  final String offText;
  final String onText;
  final Duration delay;

  @override
  State<AutoToggle> createState() => _AutoToggleState();
}

class _AutoToggleState extends State<AutoToggle> {
  bool _on = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.revealed) _schedule();
  }

  @override
  void didUpdateWidget(AutoToggle old) {
    super.didUpdateWidget(old);
    if (widget.revealed && !old.revealed) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _on = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dur = Duration(milliseconds: 500);
    final p = OnbPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 토글 OFF 트랙: HTML 라이트 #D8D9D0 / 다크 #3A3A46
    final offTrack = isDark ? const Color(0xFF3A3A46) : const Color(0xFFD8D9D0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: const Alignment(0.3, -1), // 165deg 근사
          end: const Alignment(-0.3, 1),
          colors: [p.card, p.bgSoft],
        ),
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 우상단 glow
          Positioned(
            top: -20,
            right: -20,
            child: AnimatedOpacity(
              opacity: _on ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [widget.color.withValues(alpha: 0.18), widget.color.withValues(alpha: 0)],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: dur,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _on ? widget.color : p.textDim,
                        ),
                        child: Text(_on ? widget.onText : widget.offText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 스위치
                AnimatedContainer(
                  duration: dur,
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _on ? widget.color : offTrack,
                    boxShadow: _on
                        ? [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 20)]
                        : null,
                  ),
                  child: AnimatedAlign(
                    duration: dur,
                    curve: onbSpring, // knob 스프링 오버슈트
                    alignment: _on ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
