import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'onboarding_tokens.dart';

/// 화이트보드 시각화 (학생 실시간 강의 / 강사 실시간 수업).
///
/// 마스터 컨트롤러(1850ms) 하나로 HTML의 stagger 타이밍을 재현한다:
///  - draw-path(가로축)  0.35s~  : stroke-dashoffset draw, 토스 커브
///  - draw-path d2(세로축) 0.50s~
///  - draw-path d3(포물선) 0.65s~
///  - red dot(꼭짓점)     0.0s~  : fade
///  - 수식 텍스트 f1/f2/f3 1.15/1.3/1.45s : fade
///
/// 선/곡선/텍스트는 viewBox 240x160(=aspect 1.5, 균일 스케일) 좌표로 [CustomPainter]에서
/// 직접 그린다. 마이크 버튼만 역할 색이라 SVG 오버레이.
class WhiteboardViz extends StatefulWidget {
  const WhiteboardViz({
    super.key,
    required this.revealed,
    required this.accent, // 마이크 버튼 색 (역할 point)
  });

  final bool revealed;
  final Color accent;

  @override
  State<WhiteboardViz> createState() => _WhiteboardVizState();
}

class _WhiteboardVizState extends State<WhiteboardViz> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1850));

  @override
  void initState() {
    super.initState();
    if (widget.revealed) _c.forward();
  }

  @override
  void didUpdateWidget(WhiteboardViz old) {
    super.didUpdateWidget(old);
    if (widget.revealed && !old.revealed) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const String _micSvg =
      '<svg viewBox="0 0 24 24" fill="none"><rect x="9" y="3" width="6" height="11" rx="3" fill="#0B0B0F"/>'
      '<path d="M6 11a6 6 0 0012 0M12 17v3" stroke="#0B0B0F" stroke-width="2" stroke-linecap="round"/></svg>';

  @override
  Widget build(BuildContext context) {
    // reduced-motion: 즉시 완료 상태
    if (MediaQuery.of(context).disableAnimations && _c.value != 1) {
      _c.value = 1;
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: OnbPalette.of(context).line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(painter: _BoardPainter(_c.value)),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.accent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.4), blurRadius: 16)],
                ),
                alignment: Alignment.center,
                child: SvgPicture.string(_micSvg, width: 20, height: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.t);

  final double t; // 0..1, 1850ms 기준
  static const double _total = 1850;

  /// [startMs]부터 [durMs] 동안 진행되는 로컬 0..1 (커브 적용)
  double _seg(double startMs, double durMs, Curve curve) {
    final p = ((t * _total - startMs) / durMs).clamp(0.0, 1.0);
    return curve.transform(p);
  }

  void _drawFraction(Canvas canvas, Path path, double frac, Paint paint) {
    if (frac <= 0) return;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * frac), paint);
    }
  }

  void _text(Canvas canvas, String s, double x, double y, double size, FontWeight w, Color color, double opacity) {
    if (opacity <= 0) return;
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color.withValues(alpha: opacity), fontSize: size, fontWeight: w),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // SVG y는 baseline 기준 → 대략 윗선으로 보정
    tp.paint(canvas, Offset(x, y - size));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 240.0; // == size.height / 160 (aspect 1.5)
    canvas.save();
    canvas.scale(s);

    // --- 격자 (정적) ---
    final grid = Paint()
      ..color = const Color(0xFFE6E6E0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 50), const Offset(128, 50), grid);
    canvas.drawLine(const Offset(0, 100), const Offset(128, 100), grid);
    canvas.drawLine(const Offset(42, 0), const Offset(42, 160), grid);
    canvas.drawLine(const Offset(86, 0), const Offset(86, 160), grid);

    // --- 축/곡선 draw ---
    final axis = Paint()
      ..color = const Color(0xFF999999)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    _drawFraction(
      canvas,
      Path()..moveTo(12, 100)..lineTo(118, 100),
      _seg(350, 600, onbToss),
      axis,
    );
    _drawFraction(
      canvas,
      Path()..moveTo(64, 16)..lineTo(64, 148),
      _seg(500, 600, onbToss),
      axis,
    );
    final curve = Paint()
      ..color = const Color(0xFF5B7CFA)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawFraction(
      canvas,
      Path()..moveTo(24, 134)..quadraticBezierTo(64, 16, 104, 134),
      _seg(650, 600, onbToss),
      curve,
    );

    // --- 꼭짓점 빨강 점 (fade) ---
    final dotOp = _seg(0, 400, Curves.ease);
    if (dotOp > 0) {
      canvas.drawCircle(
        const Offset(64, 34),
        3.5,
        Paint()..color = const Color(0xFFE0556B).withValues(alpha: dotOp),
      );
    }

    // --- 우측 풀이 영역 구분선 (정적) ---
    canvas.drawLine(
      const Offset(140, 24),
      const Offset(140, 136),
      Paint()
        ..color = const Color(0xFFE6E6E0)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // --- 수식 텍스트 fade (f1/f2/f3) ---
    final f1 = _seg(1150, 400, Curves.easeOut);
    final f2 = _seg(1300, 400, Curves.easeOut);
    final f3 = _seg(1450, 400, Curves.easeOut);

    _text(canvas, 'x² + 2x', 154, 52, 16, FontWeight.w700, const Color(0xFF333333), f1);
    if (f1 > 0) {
      canvas.drawLine(
        const Offset(154, 60),
        const Offset(218, 60),
        Paint()
          ..color = const Color(0xFF5B7CFA).withValues(alpha: f1)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
    _text(canvas, '= x(x+2)', 154, 86, 14, FontWeight.w400, const Color(0xFF555555), f2);
    _text(canvas, 'x = 0, −2', 154, 116, 15, FontWeight.w700, const Color(0xFFE0556B), f3);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoardPainter old) => old.t != t;
}
