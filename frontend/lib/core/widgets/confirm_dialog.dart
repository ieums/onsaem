import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';

/// 강조 박스 스타일.
/// - [outline]: 배경 투명 + 중립 회색 테두리.
/// - [tintNeutral]: 중립 회색 틴트 배경 + 테두리 없음.
/// 두 방식 모두 값(value)은 역할색으로 표시한다.
enum ConfirmHighlightStyle { outline, tintNeutral }

/// 앱 공통 확인 다이얼로그. 제목 + 본문 + (취소 / 확인) 두 버튼.
///
/// - 확인을 누르면 `true`, 취소·바깥 탭이면 `false` 반환.
/// - 모서리 18(알림센터와 동일), 색은 [ShellTheme] 토큰을 써 다크모드에서 안 깨짐.
/// - 좌측(취소): 텍스트 버튼, 역할색 글씨(강사 연보라 / 학생 연두).
///   [cancelText]가 `null`이면 취소 버튼 없이 **확인 버튼 하나만** 뜬다(안내·알림용).
/// - 우측(확인): 알약(stadium) 채움 버튼.
///   * 배경: 위험=빨강 / 그 외 역할색(강사 연보라·학생 연두).
///   * 글씨: 라이트=흰색 / 다크=어두운 글자(배경 무관, 밝기로만 결정).
/// - [highlightLabel]·[highlightValue]가 **둘 다** 주어지면 본문과 버튼 사이에
///   강조 박스(보조 라벨 + 큰 값)를 렌더한다(예: 출금 합계 / 240,000원).
///   하나라도 없으면 박스 없이 기존 레이아웃 그대로.
///   값은 역할색으로, 박스 외형은 [highlightStyle]로 결정.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelText = '취소',
  required String confirmText,
  bool isDanger = false,
  bool isTutor = false,
  String? highlightLabel,
  String? highlightValue,
  ConfirmHighlightStyle highlightStyle = ConfirmHighlightStyle.outline,
  bool barrierDismissible = true,
  ThemeData? theme,
}) async {
  // 호출 화면의 (라이트/다크) shell 테마를 그대로 물려줘 다이얼로그 색이 일치하게 한다.
  // 호출 화면이 shell 테마 밖(예: 강의실)이면 theme을 명시적으로 넘겨 다크모드가 먹게 한다.
  final resolvedTheme = theme ?? Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => Theme(
      data: resolvedTheme,
      child: _ConfirmDialog(
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        isDanger: isDanger,
        isTutor: isTutor,
        highlightLabel: highlightLabel,
        highlightValue: highlightValue,
        highlightStyle: highlightStyle,
      ),
    ),
  );
  return result ?? false;
}

/// 다이얼로그 확인/액션 버튼 공통 스타일.
/// 라이트: 흰 배경 + 검정 글씨 / 다크: 어두운 배경 + 특징색 글씨 (둘 다 특징색 테두리).
/// 인라인 다이얼로그(매칭 수락·환영 보너스·결제·신고 등)에서 재사용해 톤을 통일한다.
ButtonStyle accentDialogButtonStyle({
  required Color accent,
  required bool isDark,
  double radius = 12,
  EdgeInsetsGeometry? padding,
}) {
  return FilledButton.styleFrom(
    backgroundColor: isDark ? AppColors.shellDetailDark : Colors.white,
    foregroundColor: isDark ? accent : Colors.black,
    side: BorderSide(color: accent, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    padding: padding,
  );
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.cancelText,
    required this.confirmText,
    required this.isDanger,
    required this.isTutor,
    required this.highlightLabel,
    required this.highlightValue,
    required this.highlightStyle,
  });

  final String title;
  final String message;
  final String? cancelText;
  final String confirmText;
  final bool isDanger;
  final bool isTutor;
  final String? highlightLabel;
  final String? highlightValue;
  final ConfirmHighlightStyle highlightStyle;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 역할색: 강사=연보라(primaryBlue), 학생=연두(studentPoint).
    final roleColor =
        isTutor ? AppColors.primaryBlue : AppColors.studentPoint;
    // 확인 버튼: 흰 배경 + 특징색 테두리 + 검정 글씨(둥근 네모). 위험 액션이면 테두리 빨강.
    final accentColor = isDanger ? AppColors.logoutRed : roleColor;

    // 강조 박스는 label·value가 둘 다 있을 때만. 없으면 content는 기존 그대로(회귀 방지).
    final hasHighlight = highlightLabel != null && highlightValue != null;
    final messageWidget = Text(
      message,
      style: TextStyle(
        fontSize: 14.5,
        height: 1.45,
        color: shell.subtitleColor,
      ),
    );

    return AlertDialog(
      backgroundColor: shell.cardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: shell.titleColor,
        ),
      ),
      content: hasHighlight
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                messageWidget,
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: _highlightDecoration(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlightLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: shell.hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        highlightValue!,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: roleColor, // 값은 역할색(강사 연보라 / 학생 연두)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : messageWidget,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: roleColor),
            child: Text(
              cancelText!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            // 라이트: 흰 배경 + 검정 글씨 / 다크: 어두운 배경 + 특징색 글씨 (둘 다 특징색 테두리).
            backgroundColor: isDark ? shell.detailBackground : Colors.white,
            foregroundColor: isDark ? accentColor : Colors.black,
            side: BorderSide(color: accentColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  /// 강조 박스 외형. 값 글씨는 항상 역할색이고, 박스 배경/테두리만 스타일별로 다르다.
  BoxDecoration _highlightDecoration(bool isDark) {
    final radius = BorderRadius.circular(12);
    switch (highlightStyle) {
      case ConfirmHighlightStyle.outline:
        // 배경 투명 + 중립 회색 테두리(라이트=또렷, 다크=옅게).
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: Border.all(
            color: isDark
                ? const Color(0xFF3A4150)
                : const Color(0xFFC9CFD8),
            width: 1.2,
          ),
        );
      case ConfirmHighlightStyle.tintNeutral:
        // 중립 회색 틴트(라이트=은은히 진하게, 다크=옅게) + 테두리 없음.
        return BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: radius,
        );
    }
  }
}
