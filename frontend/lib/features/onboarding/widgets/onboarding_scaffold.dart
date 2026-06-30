import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'onboarding_tokens.dart';
import 'pulse_glow_button.dart';

/// 온보딩 한 섹션의 콘텐츠를 만드는 빌더. [revealed]는 해당 섹션이 뷰포트에
/// 들어와 등장 애니메이션을 재생해야 하는지 여부.
typedef OnbSectionBuilder = Widget Function(BuildContext context, bool revealed);

/// 학생/강사 공통 온보딩 셸.
///  - 세로 스크롤(섹션마다 뷰포트 높이)
///  - VisibilityDetector로 섹션 reveal(0.15) / 현재 섹션(0.5) 추적
///  - 우측 진행점, 우상단 건너뛰기, 마지막 섹션에서 하단 CTA 페이드인
class OnboardingScaffold extends StatefulWidget {
  const OnboardingScaffold({
    super.key,
    required this.roleColor,
    required this.sections,
    this.ctaLabel = '시작하기',
    this.onRoleColor,
    this.onStart,
    this.onSkip,
  });

  final Color roleColor;
  final List<OnbSectionBuilder> sections;
  final String ctaLabel;

  /// CTA 라벨 색(포인트 위 글자). null이면 현재 팔레트 [OnbPalette.bg]로 폴백
  /// → 다크 화면은 기존(near-black)과 동일하게 유지.
  final Color? onRoleColor;

  final VoidCallback? onStart;
  final VoidCallback? onSkip;

  @override
  State<OnboardingScaffold> createState() => _OnboardingScaffoldState();
}

class _OnboardingScaffoldState extends State<OnboardingScaffold> {
  late final List<bool> _revealed = List<bool>.filled(widget.sections.length, false);
  int _current = 0;

  @override
  void initState() {
    super.initState();
    // 진행점/CTA가 스크롤에 빠르게 따라오도록 감지 주기 단축
    VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 100);
  }

  void _onVis(int i, double fraction, bool reduce) {
    var changed = false;
    // 섹션이 충분히(약 절반) 보일 때 등장 1회 — 도착 전 미리 재생 방지.
    if (fraction >= onbRevealVisibleFraction && !_revealed[i]) {
      _revealed[i] = true;
      changed = true;
    }
    if (fraction >= 0.5 && _current != i) {
      _current = i;
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    final vh = MediaQuery.of(context).size.height;
    final last = widget.sections.length - 1;
    final showCta = _current == last;

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          // 스크롤 본문
          SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < widget.sections.length; i++)
                  SizedBox(
                    height: vh,
                    child: VisibilityDetector(
                      key: ValueKey('onb_sec_$i'),
                      onVisibilityChanged: (info) => _onVis(i, info.visibleFraction, reduce),
                      child: widget.sections[i](context, _revealed[i] || reduce),
                    ),
                  ),
              ],
            ),
          ),

          // 진행점
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.sections.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      width: 7,
                      height: _current == i ? 20 : 7,
                      decoration: BoxDecoration(
                        color: _current == i ? widget.roleColor : p.textDim,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 건너뛰기
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      '건너뛰기',
                      style: TextStyle(color: p.textDim, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 하단 CTA (마지막 섹션에서만)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !showCta,
              child: AnimatedOpacity(
                opacity: showCta ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      // 끝 색은 배경색의 alpha 0 — Colors.transparent(투명 검정)을 쓰면
                      // 라이트(#FBFBF8)에서 회색 띠가 생기므로 bg의 RGB를 유지한 채 알파만 0.
                      colors: [p.bg, p.bg, p.bg.withValues(alpha: 0)],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: PulseGlowButton(
                        label: widget.ctaLabel,
                        color: widget.roleColor,
                        labelColor: widget.onRoleColor,
                        onTap: widget.onStart,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 섹션 내 요소 하나를 reveal(페이드인 + 40px 슬라이드업, onbToss 900ms,
/// [order]*80ms stagger)로 감싼다.
class OnbReveal extends StatelessWidget {
  const OnbReveal({super.key, required this.revealed, required this.order, required this.child});

  final bool revealed;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final delay = (80 * order).ms;
    return child
        .animate(target: revealed ? 1 : 0)
        .fadeIn(duration: OnbDur.reveal, delay: delay, curve: onbToss)
        .moveY(begin: 40, end: 0, duration: OnbDur.reveal, delay: delay, curve: onbToss);
  }
}

/// 일반 섹션 레이아웃(번호칩 + 라벨 / 제목 / 부제 / 비주얼)을 reveal 스태거로 조립.
/// 학생·강사 공통.
class OnbSection extends StatelessWidget {
  const OnbSection({
    super.key,
    required this.revealed,
    required this.point,
    required this.stepNo,
    required this.label,
    required this.title,
    required this.sub,
    required this.viz,
    this.onPoint,
  });

  final bool revealed;
  final Color point;

  /// 스텝 번호칩 글자색(포인트 위). null이면 [OnbPalette.bg]로 폴백(다크 보존).
  final Color? onPoint;

  final String stepNo;
  final String label;

  /// 제목 인라인 스팬(강조 부분은 color=point 스팬으로). '\n' 줄바꿈 허용.
  final List<InlineSpan> title;

  /// 부제 텍스트('\n' 허용).
  final String sub;

  final Widget viz;

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnbReveal(revealed: revealed, order: 0, child: _stepNum(p)),
          const SizedBox(height: 20),
          OnbReveal(
            revealed: revealed,
            order: 1,
            child: Text.rich(
              TextSpan(children: title),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.68,
                height: 1.25,
                color: p.text,
              ),
            ),
          ),
          const SizedBox(height: 18),
          OnbReveal(
            revealed: revealed,
            order: 2,
            child: Text(
              sub,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: p.textSub,
                height: 1.6,
                letterSpacing: -0.17,
              ),
            ),
          ),
          const SizedBox(height: 36),
          OnbReveal(revealed: revealed, order: 3, child: viz),
        ],
      ),
    );
  }

  Widget _stepNum(OnbPalette p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: point,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [BoxShadow(color: point.withValues(alpha: 0.4), blurRadius: 16)],
          ),
          child: Text(
            stepNo,
            style: TextStyle(color: onPoint ?? p.bg, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: p.textDim,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.26,
          ),
        ),
      ],
    );
  }
}
