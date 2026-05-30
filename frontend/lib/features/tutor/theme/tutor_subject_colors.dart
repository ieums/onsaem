import 'package:flutter/material.dart';

/// 과목 배지 색 (라이트/다크)
abstract final class TutorSubjectColors {
  static const _themes = <String, _SubjectPalette>{
    '국어': _SubjectPalette(
      lightText: Color(0xFFE57373),
      lightBg: Color(0xFFFFF0F0),
      darkText: Color(0xFFFFABAB),
      darkBg: Color(0xFF4A3232),
    ),
    '수학': _SubjectPalette(
      lightText: Color(0xFFE89A56),
      lightBg: Color(0xFFFFF4E8),
      darkText: Color(0xFFFFC48A),
      darkBg: Color(0xFF4A3828),
    ),
    '영어': _SubjectPalette(
      lightText: Color(0xFFE0B85C),
      lightBg: Color(0xFFFFFAED),
      darkText: Color(0xFFFFE08A),
      darkBg: Color(0xFF454028),
    ),
    '사회': _SubjectPalette(
      lightText: Color(0xFF6BAD80),
      lightBg: Color(0xFFEFF7F2),
      darkText: Color(0xFF9FD4B0),
      darkBg: Color(0xFF2A3D32),
    ),
    '과학': _SubjectPalette(
      lightText: Color(0xFF72A8D4),
      lightBg: Color(0xFFEAF3FB),
      darkText: Color(0xFFA8CEEE),
      darkBg: Color(0xFF283848),
    ),
  };

  static (Color text, Color background) badgeColors(
    String subject,
    Brightness brightness,
  ) {
    final palette = _themes[subject];
    if (palette == null) {
      return brightness == Brightness.dark
          ? (const Color(0xFFB8BFC9), const Color(0xFF2A2E38))
          : (const Color(0xFF6B7280), const Color(0xFFF0F2F7));
    }
    return brightness == Brightness.dark
        ? (palette.darkText, palette.darkBg)
        : (palette.lightText, palette.lightBg);
  }
}

class _SubjectPalette {
  const _SubjectPalette({
    required this.lightText,
    required this.lightBg,
    required this.darkText,
    required this.darkBg,
  });

  final Color lightText;
  final Color lightBg;
  final Color darkText;
  final Color darkBg;
}
