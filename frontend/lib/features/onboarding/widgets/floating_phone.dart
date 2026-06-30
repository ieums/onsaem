import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'breathing_glow.dart';
import 'onboarding_tokens.dart';

/// 학생 "사진 찍기" 섹션의 떠 있는 폰(student_phone.png).
///
/// 첨부 HTML(onsaem_student_phone.html) 사양을 합성:
///  - 박스/테두리 없음, 배경 위 floating + 뒤 은은한 후광(BreathingGlow)
///  - float3d 3.5s: translateY 0→-12, rotate ±1.4°
///  - 바닥 그림자: float와 동기로 작아지고 옅어짐(scale 1→0.78, opacity 0.9→0.5)
///  - shutter 2.8s 토스: 46~53%에서 scale 0.945→1.025 오버슈트(+미세 rotate)
///  - camFlash 2.8s: 폰 주변 원형 버스트(흰→point-bright), 최고 opacity 0.42
///  - sparkle 4개: 4-포인트 별 staggered twinkle
class FloatingPhone extends StatefulWidget {
  const FloatingPhone({super.key, required this.role});

  final OnbRolePalette role;

  @override
  State<FloatingPhone> createState() => _FloatingPhoneState();
}

class _FloatingPhoneState extends State<FloatingPhone>
    with TickerProviderStateMixin {
  // float + ground (3.5s 왕복 = 1.75s reverse)
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1750))
        ..repeat(reverse: true);
  // shutter + flash + sparkle (2.8s 1방향 루프)
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
        ..repeat();

  @override
  void dispose() {
    _float.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// 구간 선형보간: [stops] 사이를 [vals]로 lerp.
  static double _kf(double u, List<double> stops, List<double> vals) {
    if (u <= stops.first) return vals.first;
    if (u >= stops.last) return vals.last;
    for (var i = 0; i < stops.length - 1; i++) {
      if (u <= stops[i + 1]) {
        final t = (u - stops[i]) / (stops[i + 1] - stops[i]);
        return lerpDouble(vals[i], vals[i + 1], t)!;
      }
    }
    return vals.last;
  }

  static const String _starSvg =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c.7 6.3 5 10.6 12 12'
      '-7 1.4-11.3 5.7-12 12-.7-6.3-5-10.6-12-12C7 10.6 11.3 6.3 12 0Z"/></svg>';

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final role = widget.role;
    final fx = role.phoneFx(Theme.of(context).brightness);

    return AspectRatio(
      aspectRatio: 1.5,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;

          final phone = _phoneImage(role, reduce);

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 뒤 후광
              Center(
                child: BreathingGlow(
                  size: w * 0.78,
                  color: role.point,
                  maxAlpha: 0.20,
                  stop: 0.68,
                ),
              ),

              // 바닥 그림자
              Positioned(
                bottom: h * 0.10,
                left: w * 0.27,
                width: w * 0.46,
                height: h * 0.10,
                child: reduce
                    ? _ground(role, 1, 0.7)
                    : AnimatedBuilder(
                        animation: _float,
                        builder: (_, _) {
                          final t = _float.value;
                          return _ground(
                            role,
                            lerpDouble(1, 0.78, t)!,
                            lerpDouble(0.9, 0.5, t)!,
                          );
                        },
                      ),
              ),

              // 플래시 버스트 (폰 뒤/주변)
              if (!reduce)
                Positioned(
                  left: w * 0.08,
                  right: w * 0.08,
                  top: h * 0.08,
                  bottom: h * 0.08,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, _) => Opacity(
                      opacity: (_flashOpacity(_pulse.value) * fx.flashGain).clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              fx.flashCore,
                              fx.flashMid,
                              fx.flashMid.withValues(alpha: 0),
                            ],
                            stops: const [0.0, 0.50, 0.72],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 폰 (float + shutter)
              SizedBox(
                height: h * 0.84,
                child: phone,
              ),

              // 스파클 4개
              if (!reduce) ..._sparkles(role, w, fx),
            ],
          );
        },
      ),
    );
  }

  Widget _phoneImage(OnbRolePalette role, bool reduce) {
    final img = Image.asset(
      'assets/images/student_phone.png',
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Center(
        child: Icon(Icons.smartphone_outlined,
            size: 72, color: OnbPalette.of(context).textDim),
      ),
    );
    if (reduce) return img;

    return AnimatedBuilder(
      animation: Listenable.merge([_float, _pulse]),
      builder: (_, child) {
        final f = _float.value;
        final ty = lerpDouble(0, -12, f)!;
        final floatRot = lerpDouble(-1.4, 1.4, f)! * 3.1415926 / 180;
        final u = _pulse.value;
        final sScale = _kf(u, const [0, 0.38, 0.46, 0.53, 0.64, 1],
            const [1, 1, 0.945, 1.025, 1, 1]);
        final sRot = _kf(u, const [0, 0.38, 0.46, 0.53, 0.64, 1],
                const [0, 0, -1.2, 0.6, 0, 0]) *
            3.1415926 /
            180;
        return Transform.translate(
          offset: Offset(0, ty),
          child: Transform.rotate(
            angle: floatRot,
            child: Transform.rotate(
              angle: sRot,
              alignment: const Alignment(0, 0.2),
              child: Transform.scale(
                scale: sScale,
                alignment: const Alignment(0, 0.2),
                child: child,
              ),
            ),
          ),
        );
      },
      child: img,
    );
  }

  Widget _ground(OnbRolePalette role, double scale, double opacity) {
    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  role.deep.withValues(alpha: 0.28),
                  role.deep.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.70],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 플래시 opacity 키프레임: 0/40/62/100→0, 47→0.42, 50→0.18
  static double _flashOpacity(double u) {
    return _kf(u, const [0, 0.40, 0.47, 0.50, 0.62, 1],
        const [0, 0, 0.42, 0.18, 0, 0]);
  }

  /// 별 + (라이트에서만) 번지는 드롭섀도우. 다크는 그림자 없이 별만(회귀 없음).
  Widget _star(Color starColor, OnbPhoneFx fx) {
    final bright = SvgPicture.string(
      _starSvg,
      colorFilter: ColorFilter.mode(starColor, BlendMode.srcIn),
    );
    if (fx.sparkleShadowBlur <= 0) return bright;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: fx.sparkleShadowBlur,
            sigmaY: fx.sparkleShadowBlur,
          ),
          child: SvgPicture.string(
            _starSvg,
            colorFilter: ColorFilter.mode(fx.sparkleShadow, BlendMode.srcIn),
          ),
        ),
        bright,
      ],
    );
  }

  List<Widget> _sparkles(OnbRolePalette role, double w, OnbPhoneFx fx) {
    // (top?, left?, right?, bottom?, size, phase)
    final defs = <({double? top, double? left, double? right, double? bottom, double size, double phase})>[
      (top: 0.16, left: 0.18, right: null, bottom: null, size: 24, phase: 0.0),
      (top: 0.24, left: null, right: 0.16, bottom: null, size: 17, phase: 0.03),
      (top: null, left: 0.24, right: null, bottom: 0.22, size: 14, phase: 0.05),
      (top: null, left: null, right: 0.20, bottom: 0.28, size: 20, phase: 0.01),
    ];
    return [
      for (final d in defs)
        Positioned(
          top: d.top == null ? null : d.top! * (w / 1.5),
          bottom: d.bottom == null ? null : d.bottom! * (w / 1.5),
          left: d.left == null ? null : d.left! * w,
          right: d.right == null ? null : d.right! * w,
          width: d.size,
          height: d.size,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) {
              final u = (_pulse.value + d.phase) % 1.0;
              final op = _kf(u, const [0, 0.40, 0.47, 0.60, 1], const [0, 0, 1, 0, 0]);
              final sc = _kf(u, const [0, 0.40, 0.47, 0.60, 1],
                  const [0.2, 0.2, 1.0, 0.4, 0.2]);
              final rot = _kf(u, const [0, 0.40, 0.47, 0.60, 1],
                      const [0, 0, 35, 70, 70]) *
                  3.1415926 /
                  180;
              return Opacity(
                opacity: op,
                child: Transform.rotate(
                  angle: rot,
                  child: Transform.scale(
                    scale: sc,
                    child: _star(role.bright, fx),
                  ),
                ),
              );
            },
          ),
        ),
    ];
  }
}
