import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/breathing_glow.dart';
import '../widgets/floating_phone.dart';
import '../widgets/onboarding_mascot.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/onboarding_tokens.dart';
import '../widgets/stagger_column.dart';
import '../widgets/typing_chat.dart';
import '../widgets/whiteboard_viz.dart';

/// 학생 온보딩 (라이트 기본 + 다크 지원). 첨부 onsaem_student_phone.html 기준.
///
/// 색은 모두 [OnbPalette.of] / [OnbRolePalette]를 경유 → 감싸는 Theme 밝기로 라/다 결정.
/// [onStart]/[onSkip]만 받아두며(게이팅·플래그 저장은 4단계 배선에서 연결), 갤러리에선 no-op.
class StudentOnboardingThemedScreen extends StatelessWidget {
  const StudentOnboardingThemedScreen({super.key, this.onStart, this.onSkip});

  final VoidCallback? onStart;
  final VoidCallback? onSkip;

  static const OnbRolePalette _role = OnbRolePalette.student;

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
              label: '문제 올리기',
              title: [
                const TextSpan(text: '사진 한 장이면\n'),
                TextSpan(text: '질문 끝', style: TextStyle(color: _role.point)),
              ],
              sub: '막히는 문제를 찍어 올리기만 하면\n과목과 유형은 AI가 알아서 분류해요.',
              viz: const FloatingPhone(role: _role),
            ),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '2',
              label: '강사 매칭',
              title: [
                const TextSpan(text: '강사가 '),
                TextSpan(text: '먼저', style: TextStyle(color: _role.point)),
                const TextSpan(text: ' 손들어요'),
              ],
              sub: '올린 문제에 강사들이 신청하면\n프로필을 보고 내 강사를 직접 골라요.',
              viz: _TutorListViz(revealed: r),
            ),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '3',
              label: '실시간 강의',
              title: [
                const TextSpan(text: '칠판을 '),
                TextSpan(text: '함께', style: TextStyle(color: _role.point)),
                const TextSpan(text: ' 보며\n그 자리에서'),
              ],
              sub: '공유 화이트보드와 음성으로\n막힌 문제를 실시간 1:1로 풀어요.',
              viz: WhiteboardViz(revealed: r, accent: _role.point),
            ),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '4',
              label: 'AI 튜터',
              title: [
                const TextSpan(text: '강사가 없어도\n'),
                TextSpan(text: '지금 바로', style: TextStyle(color: _role.point)),
              ],
              sub: '올린 문제 그대로 AI 튜터에게\n24시간 언제든 물어보세요.',
              viz: TypingChat(revealed: r, point: _role.point, onPoint: _role.onPoint),
            ),
        (c, r) => OnbSection(
              revealed: r,
              point: _role.point,
              onPoint: _role.onPoint,
              stepNo: '5',
              label: '복습',
              title: [
                const TextSpan(text: '끝나도\n'),
                TextSpan(text: '끝이 아니에요', style: TextStyle(color: _role.point)),
              ],
              sub: '녹화 영상과 강사 필기를 다시 보고\n이해 안 된 부분은 복습 질문까지.',
              viz: _ReplayViz(revealed: r),
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

  static const OnbRolePalette _role = OnbRolePalette.student;

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.45),
                child: BreathingGlow(size: 360, color: _role.point, maxAlpha: 0.16),
              ),
            ),
            // 빼꼼 마스코트 — 우상단 가장자리(헤드라인 안 가림)
            Positioned(
              top: c.maxHeight * 0.13,
              right: 0,
              child: const OnbPeekMascot(width: 124),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnbReveal(
                      revealed: revealed,
                      order: 1,
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: '모르면 바로,\n'),
                          TextSpan(text: '지금 바로', style: TextStyle(color: _role.point)),
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
                        '실시간 1:1 온라인 과외, 온샘',
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
      },
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

// ─────────────────────────── 3. 강사 매칭 ───────────────────────────

class _TutorListViz extends StatelessWidget {
  const _TutorListViz({required this.revealed});
  final bool revealed;

  static const OnbRolePalette _role = OnbRolePalette.student;

  @override
  Widget build(BuildContext context) {
    return StaggerColumn(
      revealed: revealed,
      children: [
        _row(context, '김수학 선생님', '수학 · 응답 빠름 · ⭐ 4.9', selected: true),
        _row(context, '이과학 선생님', '과학 · 경력 5년 · ⭐ 4.8', selected: false),
      ],
    );
  }

  Widget _row(BuildContext context, String name, String meta, {required bool selected}) {
    final p = OnbPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? _role.point : p.line),
        boxShadow: selected
            ? [BoxShadow(color: _role.point.withValues(alpha: 0.22), blurRadius: 24)]
            : null,
      ),
      child: Row(
        children: [
          _personAva(context, selected ? _role.point : p.textDim),
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
          if (selected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _role.point, width: 1.5),
              ),
              child: Text('선택',
                  style: TextStyle(color: _role.point, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

/// 역할 테마에 맞춘 인물 아바타(46x46).
Widget _personAva(BuildContext context, Color stroke) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final hex = '#${(stroke.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  return Container(
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
            : const [Color(0xFFEEF0E6), Color(0xFFE2E5D6)],
      ),
    ),
    child: SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="$hex" stroke-width="2"/>'
      '<path d="M5 20c0-4 3.5-6 7-6s7 2 7 6" stroke="$hex" stroke-width="2" stroke-linecap="round"/></svg>',
      width: 24,
      height: 24,
    ),
  );
}

// ─────────────────────────── 6. 복습 ───────────────────────────

class _ReplayViz extends StatelessWidget {
  const _ReplayViz({required this.revealed});
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final point = OnbRolePalette.student.point;
    final pointHex =
        '#${(point.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return StaggerColumn(
      revealed: revealed,
      children: [
        _item(
          context,
          '<svg viewBox="0 0 24 24" fill="none"><path d="M9 7l8 5-8 5V7z" fill="$pointHex"/></svg>',
          '이차방정식 풀이',
          '녹화 영상 · 28분',
        ),
        _item(
          context,
          '<svg viewBox="0 0 24 24" fill="none"><path d="M6 4h9l4 4v12H6V4z" stroke="$pointHex" stroke-width="2" stroke-linejoin="round"/>'
          '<path d="M9 12h6M9 16h4" stroke="$pointHex" stroke-width="2" stroke-linecap="round"/></svg>',
          '강사 필기 노트',
          'PDF · 3페이지',
        ),
      ],
    );
  }

  Widget _item(BuildContext context, String svg, String name, String meta) {
    final p = OnbPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF2A2A38), Color(0xFF16161E)]
                    : const [Color(0xFFEEF0E6), Color(0xFFE2E5D6)],
              ),
            ),
            child: SvgPicture.string(svg, width: 22, height: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(meta, style: TextStyle(color: p.textSub, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── 7. 마지막 ───────────────────────────

class _Final extends StatelessWidget {
  const _Final({required this.revealed});
  final bool revealed;

  static const OnbRolePalette _role = OnbRolePalette.student;

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
              const OnbJumpMascot(asset: 'assets/images/student_jump.png', width: 150),
              const SizedBox(height: 28),
              OnbReveal(
                revealed: revealed,
                order: 0,
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: '이제 첫 문제를\n'),
                    TextSpan(text: '올려볼까요?', style: TextStyle(color: _role.point)),
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
                  '온샘과 함께 막힘 없이 공부해요.',
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
