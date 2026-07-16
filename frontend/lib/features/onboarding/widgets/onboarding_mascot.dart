import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'onboarding_tokens.dart';

/// 온보딩 마스코트 PNG 3종 + 등장/플로팅/점프 모션.
///
/// 첨부 HTML 기준:
///  - 학생 히어로: `student_peek.png` — peekIn(우→0 스프링) + peekTilt(기울기 흔들)
///  - 강사 히어로: `tutor_point.png` — pointIn(스케일 스프링) + pointFloat(둥실)
///  - 마지막 CTA: `student_jump.png`/`tutor_jump.png` — jumpBounce(점프 스쿼시)
///
/// 모든 이미지는 [Image.asset] + errorBuilder 폴백(파일 없어도 빌드 안 깨짐).
/// 자산은 assets/images/ 에 있고 pubspec에 디렉터리 단위로 이미 등록됨.

/// 학생 히어로 — 우상단에서 빼꼼(peek) 들어와 살짝 기울이며 흔들.
class OnbPeekMascot extends StatelessWidget {
  const OnbPeekMascot({super.key, this.width = 124});

  final double width;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    Widget img = _MascotImage(
      asset: 'assets/images/student_peek.png',
      width: width,
      shadow: const Offset(-6, 12),
    );

    if (reduce) return img;

    // 무한 기울기(peekTilt): rotate 0→-3°, translateY 0→-6
    img = img
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .rotate(
          begin: 0,
          end: -3 / 360,
          duration: 1600.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.bottomRight,
        )
        .moveY(begin: 0, end: -6, duration: 1600.ms, curve: Curves.easeInOut);

    // 1회 등장(peekIn): 우측(120px)에서 슬라이드 + 페이드, 스프링
    img = img
        .animate()
        .fadeIn(duration: 1200.ms, curve: onbSpring)
        .moveX(begin: 120, end: 0, duration: 1200.ms, curve: onbSpring);

    return img;
  }
}

/// 강사 히어로 — 스케일로 톡 등장 후 둥실둥실 떠다님.
class OnbPointMascot extends StatelessWidget {
  const OnbPointMascot({super.key, this.width = 190});

  final double width;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    Widget img = _MascotImage(
      asset: 'assets/images/tutor_point.png',
      width: width,
      shadow: const Offset(0, 14),
    );

    if (reduce) return img;

    // 무한 둥실(pointFloat 근사): 상하 + 미세 회전
    img = img
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -8, duration: 1700.ms, curve: Curves.easeInOut)
        .rotate(begin: -2 / 360, end: 2 / 360, duration: 1700.ms, curve: Curves.easeInOut);

    // 1회 등장(pointIn): scale 0.6→1 + 위로, 스프링
    img = img
        .animate()
        .fadeIn(duration: 1100.ms, curve: onbSpring)
        .scaleXY(begin: 0.6, end: 1, duration: 1100.ms, curve: onbSpring)
        .moveY(begin: 20, end: 0, duration: 1100.ms, curve: onbSpring);

    return img;
  }
}

/// 마지막 CTA — 바닥 중앙 기준 점프 + 스쿼시/스트레치(jumpBounce).
class OnbJumpMascot extends StatelessWidget {
  const OnbJumpMascot({super.key, required this.asset, this.width = 150});

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final img = _MascotImage(asset: asset, width: width, shadow: const Offset(0, 14));

    if (reduce) return img;

    // 점프: 바닥에선 가로로 넓고(1.05/0.95), 정점에선 세로로 길쭉(0.98/1.04).
    return img
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -50, duration: 700.ms, curve: Curves.easeInOut)
        .scale(
          begin: const Offset(1.05, 0.95),
          end: const Offset(0.98, 1.04),
          duration: 700.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.bottomCenter,
        );
  }
}

/// 공통 마스코트 이미지 + drop-shadow + 폴백.
class _MascotImage extends StatelessWidget {
  const _MascotImage({required this.asset, required this.width, required this.shadow});

  final String asset;
  final double width;
  final Offset shadow;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      fit: BoxFit.contain,
      // HTML filter:drop-shadow 근사
      // (Image 자체엔 그림자 적용이 안 되므로 약한 색조 그림자만)
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: width,
        child: Center(
          child: Icon(Icons.image_outlined,
              size: width * 0.4, color: OnbPalette.of(context).textDim),
        ),
      ),
    );
  }
}
