import 'package:flutter/material.dart';

abstract final class AppColors {

  /// ─── 화상강의 ───────────────────────────
  static const Color primary = Color(0xFF5B8DEF);
  static const Color background = Color(0xFFF5F7FF);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color error = Color(0xFFE53935);
  static const Color whiteboardBackground = Color(0xFFFAFAFA);
  static const Color penDefault = Colors.black;
  static const Color buttonDanger = Color(0xFFE53935);
  
  /// 온샘 앱 공통 컬러

  static const Color primaryBlue = Color(0xFFBFA2DB);
  /// 학생 브랜드 컬러(연두). 채움·칩·소프트 배경용. 글씨/버튼 라벨엔 [studentInk] 사용.
  static const Color studentPoint = Color(0xFFE0FFB4);
  /// 학생 강조용 진한 연두. 버튼 배경/라벨·인디케이터·강조 글씨(흰 배경·흰 글씨 대비 OK).
  static const Color studentInk = Color(0xFF4C7A1E);
  /// 액션 강조용 선명 블루 (studentPoint보다 쨍함)
  static const Color vividBlue = Color(0xFF007AFF);
  static const Color incomeGreen = Color(0xFF5FA68A);

  /// 회원가입 역할 선택 — 학생 카드용 (강사는 [primaryBlue])
  static const Color roleStudentAccent = studentPoint;
  static const Color roleStudentBorder = Color(0xFFB6E08A);
  static const Color logoutRed = Color(0xFFE53935);
  static const Color white = Colors.white;
  static const Color white70 = Color(0xB3FFFFFF);

  /// 보라(primary) 채움 위 텍스트·아이콘 — 라이트: 흰색, 다크: 어두운 글자
  static Color onPrimaryFill(Brightness brightness) =>
      brightness == Brightness.dark ? shellOnSurfaceLight : white;

  // 강사·학생 탭 — [AppTheme.shell] / [AppTheme.shellDark]에서만 사용

  static const Color shellScaffoldLight = Color(0xFFF8F9FD);
  static const Color shellSurfaceLight = Colors.white;
  static const Color shellOnSurfaceLight = Color(0xFF1A1D26);
  static const Color shellSubtitleLight = Color(0xFF5B6475);
  static const Color shellHintLight = Color(0xFF9AA3B2);
  static const Color shellCardBorderLight = Color(0xFFEDEFF5);
  static const Color shellDividerLight = Color(0xFFF0F2F7);
  static const Color shellDetailLight = Color(0xFFF3F4F8);
  static const Color shellIconBgLight = Color(0xFFF3F0FA);
  static const Color shellTabBarLight = Colors.white;
  static const Color shellTrackOffLight = Color(0xFFD8D8D8);
  static const Color shellSnackBarDark = Color(0xFF2A2E38);

  static const Color shellScaffoldDark = Color(0xFF14161C);
  static const Color shellSurfaceDark = Color(0xFF1E2129);
  static const Color shellOnSurfaceDark = Color(0xFFC5CAD3);
  static const Color shellSubtitleDark = Color(0xFFB8BFC9);
  static const Color shellHintDark = Color(0xFF8B939F);
  static const Color shellCardBorderDark = Color(0xFF2E3340);
  static const Color shellDividerDark = Color(0xFF2A2E38);
  static const Color shellDetailDark = Color(0xFF252932);
  static const Color shellIconBgDark = Color(0xFF2A2E38);
  static const Color shellTabBarDark = Color(0xFF1A1D24);
  static const Color shellTrackOffDark = Color(0xFF4A4F5C);

  /// 복습 북마크·TIP 강조
  static const Color reviewHighlight = Color(0xFFF5A623);
}
