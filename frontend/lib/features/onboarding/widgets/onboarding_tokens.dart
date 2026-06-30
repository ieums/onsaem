import 'package:flutter/material.dart';

/// 온보딩 deluxe 공통 디자인 토큰.
/// HTML `:root` 변수와 1:1 대응. bg/card/text 계열은 학생·강사 공통이고,
/// point(역할 색)만 화면별로 다르므로 위젯에 파라미터로 주입한다.
class OnbColors {
  OnbColors._();

  static const Color bg = Color(0xFF0B0B0F); // --bg
  static const Color bgSoft = Color(0xFF14141B); // --bg-soft
  static const Color card = Color(0xFF1A1A23); // --card
  static const Color cardSoft = Color(0xFF20202B); // --card-soft
  static const Color text = Color(0xFFF4F5F0); // --text
  static const Color textSub = Color(0xFF9A9AA5); // --text-sub
  static const Color textDim = Color(0xFF5C5C68); // --text-dim
  static const Color line = Color(0x12FFFFFF); // --line rgba(255,255,255,0.07)

  /// 역할 포인트 색 (--point)
  static const Color studentPoint = Color(0xFFD2E096); // 연두
  static const Color tutorPoint = Color(0xFFBFA2DB); // 연보라
}

/// 온보딩 중립(neutral) 색 팔레트 — 라이트/다크 두 벌.
///
/// 기존 [OnbColors](다크 전용)와 달리, 첨부 HTML의 라이트가 **기본**이고 다크도 지원한다.
/// 위젯/화면은 색을 하드코딩하지 말고 `OnbPalette.of(context)`로 받는다.
/// 역할 포인트색(학생/강사)은 테마와 무관하므로 [OnbRolePalette]로 따로 주입한다.
@immutable
class OnbPalette {
  const OnbPalette({
    required this.bg,
    required this.bgSoft,
    required this.card,
    required this.cardSoft,
    required this.text,
    required this.textSub,
    required this.textDim,
    required this.line,
  });

  final Color bg;
  final Color bgSoft;
  final Color card;
  final Color cardSoft;
  final Color text;
  final Color textSub;
  final Color textDim;
  final Color line;

  /// 라이트(기본) — HTML `:root` 라이트 토큰.
  static const OnbPalette light = OnbPalette(
    bg: Color(0xFFFBFBF8),
    bgSoft: Color(0xFFF2F3ED),
    card: Color(0xFFFFFFFF),
    cardSoft: Color(0xFFF7F8F2),
    text: Color(0xFF1A1B16),
    textSub: Color(0xFF6B6D64),
    textDim: Color(0xFFA3A59A),
    line: Color(0x14000000), // rgba(0,0,0,0.08)
  );

  /// 다크 — 기존 [OnbColors] 값과 1:1(다크 온보딩 시각 보존).
  static const OnbPalette dark = OnbPalette(
    bg: OnbColors.bg,
    bgSoft: OnbColors.bgSoft,
    card: OnbColors.card,
    cardSoft: OnbColors.cardSoft,
    text: OnbColors.text,
    textSub: OnbColors.textSub,
    textDim: OnbColors.textDim,
    line: OnbColors.line,
  );

  /// 현재 Theme 밝기로 라/다 선택.
  static OnbPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// 온보딩 역할(학생/강사) 포인트 색 번들. HTML `--point` 계열 + 포인트 위 글자색.
@immutable
class OnbRolePalette {
  const OnbRolePalette({
    required this.point,
    required this.bright,
    required this.deep,
    required this.onPoint,
  });

  /// 메인 포인트(`--point`).
  final Color point;

  /// 밝은 변형(`--point-bright`) — 플래시/스파클.
  final Color bright;

  /// 진한 변형(`--point-deep`) — 그림자/대비.
  final Color deep;

  /// 포인트 채움 위 글자/아이콘 색(스텝칩·CTA 라벨). HTML 라이트 기준.
  final Color onPoint;

  /// 학생(연두).
  static const OnbRolePalette student = OnbRolePalette(
    point: Color(0xFFD2E096),
    bright: Color(0xFFE3F0AE),
    deep: Color(0xFF8A9B5C),
    onPoint: Color(0xFF3A4222),
  );

  /// 강사(연보라).
  static const OnbRolePalette tutor = OnbRolePalette(
    point: Color(0xFFBFA2DB),
    bright: Color(0xFFD4BEEC),
    deep: Color(0xFF8B6FB0),
    onPoint: Color(0xFFFFFFFF),
  );

  /// 학생 폰 섹션(FloatingPhone)의 플래시/스파클 효과 색 — 라/다 분리.
  ///
  /// 라이트(밝은 배경 #FBFBF8)에선 흰~연한색이 묻히므로 플래시를 포인트 계열로
  /// 진하게, 스파클엔 [deep] 번짐 그림자를 깐다. 다크는 기존(흰 코어·그림자 없음) 유지.
  OnbPhoneFx phoneFx(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return OnbPhoneFx(
        flashCore: const Color(0xFFFFFFFF),
        flashMid: bright,
        flashGain: 1.0, // 기존 피크(0.42) 유지 — 다크 회귀 방지
        sparkleShadow: const Color(0x00000000),
        sparkleShadowBlur: 0,
      );
    }
    return OnbPhoneFx(
      flashCore: point,
      flashMid: deep,
      flashGain: 1.7, // 라이트는 더 "번쩍" (피크 ≈ 0.71)
      sparkleShadow: deep.withValues(alpha: 0.92),
      sparkleShadowBlur: 4.5,
    );
  }
}

/// FloatingPhone 효과(플래시/스파클) 색·그림자 토큰(테마별 값은 [OnbRolePalette.phoneFx]).
@immutable
class OnbPhoneFx {
  const OnbPhoneFx({
    required this.flashCore,
    required this.flashMid,
    required this.flashGain,
    required this.sparkleShadow,
    required this.sparkleShadowBlur,
  });

  /// 플래시 버스트 중심색.
  final Color flashCore;

  /// 플래시 버스트 중간색(가장자리는 이 색의 alpha 0으로 페이드).
  final Color flashMid;

  /// 플래시 불투명도 배율(키프레임 피크 0.42에 곱함). 다크 1.0, 라이트 ↑.
  final double flashGain;

  /// 스파클 드롭섀도우 색(번지는 후광). 다크에선 투명.
  final Color sparkleShadow;

  /// 스파클 그림자 blur 시그마. 0이면 그림자 없음(다크).
  final double sparkleShadowBlur;
}

/// 토스 등장 커브 — cubic-bezier(0.16, 1, 0.3, 1)
const Curve onbToss = Cubic(0.16, 1.0, 0.3, 1.0);

/// 스프링(오버슈트) 커브 — cubic-bezier(0.34, 1.56, 0.64, 1)
const Curve onbSpring = Cubic(0.34, 1.56, 0.64, 1.0);

/// 섹션 등장(reveal) 발동 임계치 — 섹션이 뷰포트의 이 비율 이상 보이면 1회 재생.
/// 너무 낮으면(예: 0.15) 도착 전에 미리 터지므로, 실제 도착 시점(약 절반 노출)에 맞춤.
/// 실기기 보고 0.4~0.6 사이로 미세조정 가능. (진행점 dots 판정은 별도 0.5 유지)
const double onbRevealVisibleFraction = 0.5;

/// 공통 Duration 상수
class OnbDur {
  OnbDur._();

  /// reveal 등장 (opacity/transform 0.9s)
  static const Duration reveal = Duration(milliseconds: 900);

  /// 카운트업 (1.4s)
  static const Duration countUp = Duration(milliseconds: 1400);

  /// 스태거 dropIn 각 항목 (0.6s)
  static const Duration drop = Duration(milliseconds: 600);
}
