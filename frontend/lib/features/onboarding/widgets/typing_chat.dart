import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'onboarding_tokens.dart';

/// AI 튜터 채팅 타임라인 (학생).
///
/// HTML 순서:
///  - q 버블 등장 0.25s (스프링 bubbleIn)
///  - typing 인디케이터 등장 0.7s, 점 3개 blink
///  - typing 붕괴(max-height→0) ~1.95s
///  - a 버블 등장 2.2s (스프링 bubbleIn)
///
/// max-height 트랜지션은 Flutter에 없어 [AnimatedSize]로 근사한다.
class TypingChat extends StatefulWidget {
  const TypingChat({
    super.key,
    required this.revealed,
    required this.point,
    this.onPoint,
    this.question = '이 이차방정식 어떻게 풀어요?',
    this.answer = '근의 공식을 쓰면 돼요. 먼저 a, b, c를 찾고 판별식부터 확인해볼까요?',
    this.aiTag = 'AI 튜터',
  });

  final bool revealed;
  final Color point;

  /// 질문 버블(포인트 채움) 위 글자색. null이면 [OnbPalette.bg]로 폴백(다크 보존).
  final Color? onPoint;
  final String question;
  final String answer;
  final String aiTag;

  @override
  State<TypingChat> createState() => _TypingChatState();
}

class _TypingChatState extends State<TypingChat> {
  bool _q = false;
  bool _typing = false;
  bool _collapsed = false;
  bool _a = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    if (widget.revealed) _start();
  }

  @override
  void didUpdateWidget(TypingChat old) {
    super.didUpdateWidget(old);
    if (widget.revealed && !old.revealed) _start();
  }

  void _start() {
    _timers
      ..add(Timer(const Duration(milliseconds: 250), () => _set(() => _q = true)))
      ..add(Timer(const Duration(milliseconds: 700), () => _set(() => _typing = true)))
      ..add(Timer(const Duration(milliseconds: 1950), () => _set(() => _collapsed = true)))
      ..add(Timer(const Duration(milliseconds: 2200), () => _set(() => _a = true)));
  }

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final showQ = _q || reduce;
    final showA = _a || reduce;
    final showTyping = _typing && !_collapsed && !reduce;

    return LayoutBuilder(
      builder: (context, c) {
        final maxBubble = c.maxWidth * 0.8;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // q
            Align(
              alignment: Alignment.centerRight,
              child: _springIn(
                show: showQ,
                child: _qBubble(maxBubble),
              ),
            ),
            // typing (붕괴 가능)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: showTyping
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedOpacity(
                          opacity: _typing ? 1 : 0,
                          duration: const Duration(milliseconds: 270),
                          child: _typingBubble(),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
            // a
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _springIn(
                  show: showA,
                  child: _aBubble(maxBubble),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// bubbleIn — translateY(10)→0, scale(0.96)→1, fade, 스프링
  Widget _springIn({required bool show, required Widget child}) {
    return child
        .animate(target: show ? 1 : 0)
        .fadeIn(duration: 450.ms, curve: onbSpring)
        .scaleXY(begin: 0.96, end: 1, duration: 450.ms, curve: onbSpring)
        .moveY(begin: 10, end: 0, duration: 450.ms, curve: onbSpring);
  }

  Widget _qBubble(double maxWidth) {
    final p = OnbPalette.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: widget.point,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(
          widget.question,
          style: TextStyle(
            color: widget.onPoint ?? p.bg,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _aBubble(double maxWidth) {
    final p = OnbPalette.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: p.card,
          border: Border.all(color: p.line),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.aiTag,
              style: TextStyle(color: widget.point, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.answer,
              style: TextStyle(
                color: p.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() {
    final p = OnbPalette.of(context);
    Widget dot(int i) => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: p.textDim, shape: BoxShape.circle),
        )
            .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
            .moveY(begin: 0, end: -3, duration: 600.ms, delay: (i * 200).ms, curve: Curves.easeInOut)
            .fade(begin: 0.3, end: 1.0, duration: 600.ms, delay: (i * 200).ms, curve: Curves.easeInOut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: p.card,
        border: Border.all(color: p.line),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [dot(0), const SizedBox(width: 5), dot(1), const SizedBox(width: 5), dot(2)],
      ),
    );
  }
}
