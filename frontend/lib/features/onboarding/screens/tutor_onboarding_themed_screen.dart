import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/auto_toggle.dart';
import '../widgets/breathing_glow.dart';
import '../widgets/count_up_text.dart';
import '../widgets/onboarding_mascot.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/onboarding_tokens.dart';
import '../widgets/stagger_column.dart';
import '../widgets/whiteboard_viz.dart';

/// 강사 온보딩 (라이트 기본 + 다크 지원). 첨부 onsaem_tutor_e.html 기준.
///
/// 폰/카메라 섹션은 없고 마스코트는 히어로(가리키기) + 마지막(점프) 2개.
class TutorOnboardingThemedScreen extends StatelessWidget {
  const TutorOnboardingThemedScreen({super.key, this.onStart, this.onSkip});

  final VoidCallback? onStart;
  final VoidCallback? onSkip;

  static const OnbRolePalette _role = OnbRolePalette.tutor;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      roleColor: _role.point,
      onRoleColor: _role.onPoint,
      onStart: onStart,
      onSkip: onSkip,
      sections: [
        (c, r) => _Hero(revealed: r),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '1',
              label: '프로필 등록',
              title: [
                const TextSpan(text: '학생이 나를\n고르는 '),
                TextSpan(text: '첫 기준', style: TextStyle(color: _role.point)),
              ],
              sub: '전공·소개·학력을 채우면\n학생이 프로필을 보고 나를 선택해요.',
              viz: _ProfileViz(revealed: r),
            ),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '2',
              label: '온라인 켜기',
              title: [
                const TextSpan(text: '켜는 순간\n'),
                TextSpan(text: '질문이 도착', style: TextStyle(color: _role.point)),
                const TextSpan(text: '해요'),
              ],
              sub: '온라인을 켜면 내게 맞는 문제가\n실시간으로 들어와요.',
              viz: AutoToggle(revealed: r, color: _role.point),
            ),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '3',
              label: '문제 신청',
              title: [
                const TextSpan(text: '풀 수 있는 문제에\n'),
                TextSpan(text: '손들기', style: TextStyle(color: _role.point)),
              ],
              sub: '들어온 문제 중 자신 있는 걸 골라\n신청하면, 학생이 나를 선택해요.',
              viz: _ProblemListViz(revealed: r),
            ),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '4',
              label: '실시간 수업',
              title: [
                const TextSpan(text: '칠판으로\n'),
                TextSpan(text: '바로 가르쳐요', style: TextStyle(color: _role.point)),
              ],
              sub: '학생이 선택하면 즉시 수업 시작.\n공유 화이트보드와 음성으로 1:1 강의.',
              viz: WhiteboardViz(revealed: r, accent: _role.point),
            ),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '5',
              label: '정산',
              title: [
                const TextSpan(text: '수업한 만큼\n'),
                TextSpan(text: '정확하게', style: TextStyle(color: _role.point)),
              ],
              sub: '수업료는 자동으로 계산되고\n등록한 계좌로 받을 수 있어요.',
              viz: _SettleViz(revealed: r),
            ),
        (c, r) => _Final(revealed: r),
      ],
    );
  }
}

// ─────────────────────────── 1. 히어로 ───────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.revealed});
  final bool revealed;

  static const OnbRolePalette _role = OnbRolePalette.tutor;

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, -0.45),
            child: BreathingGlow(size: 360, color: _role.point, maxAlpha: 0.16),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 가리키기 마스코트 — 중앙 풀바디
                const OnbPointMascot(width: 190),
                const SizedBox(height: 24),
                OnbReveal(
                  revealed: revealed,
                  order: 1,
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: '가르치는\n'),
                      TextSpan(text: '새로운 방법', style: TextStyle(color: _role.point)),
                    ]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.2,
                      color: p.text,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OnbReveal(
                  revealed: revealed,
                  order: 2,
                  child: Text(
                    '내 시간에, 내 방식대로 — 온샘 선생님',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: p.textSub),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(bottom: 40, left: 0, right: 0, child: const _ScrollHint()),
      ],
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint();

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    final hint = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('아래로 밀어보세요',
            style: TextStyle(color: p.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: p.textDim),
      ],
    );
    if (MediaQuery.of(context).disableAnimations) return hint;
    return hint
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .moveY(begin: 0, end: 8, duration: 900.ms, curve: Curves.easeInOut);
  }
}

// ─────────────────────────── 2. 프로필 (SNS 카드) ───────────────────────────

class _ProfileViz extends StatelessWidget {
  const _ProfileViz({required this.revealed});
  final bool revealed;

  static const OnbRolePalette _role = OnbRolePalette.tutor;

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(context, p),
        const SizedBox(height: 12),
        _otherRow(context, p),
      ],
    );
  }

  Widget _card(BuildContext context, OnbPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _role.point),
        boxShadow: [
          BoxShadow(color: _role.point, blurRadius: 0, spreadRadius: 1.5),
          BoxShadow(color: _role.point.withValues(alpha: 0.25), blurRadius: 28, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FlowingBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 50, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('함한솔 선생님',
                            style: TextStyle(color: p.text, fontSize: 19, fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                          decoration: BoxDecoration(
                            color: _role.point,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [BoxShadow(color: _role.point.withValues(alpha: 0.4), blurRadius: 14)],
                          ),
                          child: Text('선택',
                              style: TextStyle(color: _role.onPoint, fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('수학 · ⭐ 4.9 · 응답 빠름',
                        style: TextStyle(color: p.textSub, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 14),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [_Ptag('서울대 수학과'), _Ptag('경력 5년')],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(top: 44, left: 22, child: _avatar(context, p)),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context, OnbPalette p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget ava = Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF2A2A38), Color(0xFF1C1C26)]
              : const [Color(0xFFEFEBF5), Color(0xFFE5DEF0)],
        ),
        border: Border.all(color: p.card, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: SvgPicture.string(
        '<svg viewBox="0 0 34 34" fill="none"><circle cx="17" cy="12" r="6" stroke="#BFA2DB" stroke-width="2.5"/>'
        '<path d="M6 29c0-6 5-9 11-9s11 3 11 9" stroke="#BFA2DB" stroke-width="2.5" stroke-linecap="round"/></svg>',
        width: 34,
        height: 34,
      ),
    );
    ava = ava
        .animate(target: revealed ? 1 : 0)
        .scaleXY(begin: 0, end: 1, delay: 300.ms, duration: 700.ms, curve: onbSpring)
        .moveY(begin: 10, end: 0, delay: 300.ms, duration: 700.ms, curve: onbSpring);
    return ava;
  }

  Widget _otherRow(BuildContext context, OnbPalette p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: 0.85,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF2A2A38), Color(0xFF1C1C26)]
                      : const [Color(0xFFEFEBF5), Color(0xFFE5DEF0)],
                ),
              ),
              child: SvgPicture.string(
                '<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="#9A9AA5" stroke-width="2"/>'
                '<path d="M5 20c0-4 3.5-6 7-6s7 2 7 6" stroke="#9A9AA5" stroke-width="2" stroke-linecap="round"/></svg>',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('다른 선생님',
                      style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('수학 · 경력 3년 · ⭐ 4.7',
                      style: TextStyle(color: p.textSub, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ptag extends StatelessWidget {
  const _Ptag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: OnbRolePalette.tutor.point.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(color: Color(0xFF8B6FB0), fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

/// 흐르는 보라 그라데이션 배너(`bannerFlow`). 색은 라/다 공통(브랜드 보라).
class _FlowingBanner extends StatelessWidget {
  const _FlowingBanner();

  @override
  Widget build(BuildContext context) {
    final banner = _box(0);
    if (MediaQuery.of(context).disableAnimations) return banner;
    return banner.animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).custom(
          duration: 2500.ms,
          curve: Curves.easeInOut,
          builder: (context, v, _) => _box(v),
        );
  }

  Widget _box(double v) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(lerpDouble(-1, 0, v)!, -1),
                  end: Alignment(lerpDouble(0, 1, v)!, 1),
                  colors: const [Color(0xFFBFA2DB), Color(0xFF8B6FB0), Color(0xFF6B5295)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.4, 0),
                  radius: 0.8,
                  colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x40000000), borderRadius: BorderRadius.circular(999)),
              child: const Text('내 프로필',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── 4. 문제 신청 ───────────────────────────

class _ProblemListViz extends StatelessWidget {
  const _ProblemListViz({required this.revealed});
  final bool revealed;

  static const OnbRolePalette _role = OnbRolePalette.tutor;

  @override
  Widget build(BuildContext context) {
    return StaggerColumn(
      revealed: revealed,
      children: [
        _row(context, '이차방정식 풀이', '고1 수학 · 5분 전', apply: true),
        _row(context, '삼각함수 그래프', '고2 수학 · 12분 전', apply: false),
      ],
    );
  }

  Widget _row(BuildContext context, String name, String meta, {required bool apply}) {
    final p = OnbPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconHex = apply ? '#BFA2DB' : '#9A9AA5';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: apply ? _role.point : p.line),
        boxShadow: apply
            ? [BoxShadow(color: _role.point.withValues(alpha: 0.3), blurRadius: 24)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF2A2A38), Color(0xFF1C1C26)]
                    : const [Color(0xFFEFEBF5), Color(0xFFE5DEF0)],
              ),
            ),
            child: SvgPicture.string(
              '<svg viewBox="0 0 24 24" fill="none"><rect x="4" y="5" width="16" height="14" rx="3" stroke="$iconHex" stroke-width="2"/>'
              '<path d="M8 10h8M8 14h5" stroke="$iconHex" stroke-width="2" stroke-linecap="round"/></svg>',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(meta, style: TextStyle(color: p.textSub, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (apply)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _role.point, width: 1.5),
              ),
              child: Text('신청',
                  style: TextStyle(color: _role.point, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────── 6. 정산 (카운트업) ───────────────────────────

class _SettleViz extends StatelessWidget {
  const _SettleViz({required this.revealed});
  final bool revealed;

  static const OnbRolePalette _role = OnbRolePalette.tutor;

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: const Alignment(0.3, -1),
          end: const Alignment(-0.3, 1),
          colors: [p.card, p.bgSoft],
        ),
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            left: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_role.point.withValues(alpha: 0.10), _role.point.withValues(alpha: 0)],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('이번 달 정산 예정',
                    style: TextStyle(color: p.textSub, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                CountUpText(
                  target: 312000,
                  active: revealed,
                  style: TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w800, color: _role.point, letterSpacing: -0.76),
                ),
                _settleRow(p, '완료한 수업', '8회'),
                _settleRow(p, '출금 가능', '계좌로 바로'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settleRow(OnbPalette p, String d, String v) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(d, style: TextStyle(color: p.textSub, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(v, style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────── 7. 마지막 ───────────────────────────

class _Final extends StatelessWidget {
  const _Final({required this.revealed});
  final bool revealed;

  static const OnbRolePalette _role = OnbRolePalette.tutor;

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.55),
            child: BreathingGlow(size: 340, color: _role.point, maxAlpha: 0.14),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OnbJumpMascot(asset: 'assets/images/tutor_jump.png', width: 150),
              const SizedBox(height: 28),
              OnbReveal(
                revealed: revealed,
                order: 0,
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: '이제 프로필을\n'),
                    TextSpan(text: '채워볼까요?', style: TextStyle(color: _role.point)),
                  ]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.64,
                    height: 1.3,
                    color: p.text,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OnbReveal(
                revealed: revealed,
                order: 1,
                child: Text(
                  '온샘에서 첫 수업을 시작해요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: p.textSub),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
