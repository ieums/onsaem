import 'package:flutter/material.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';

/// 학생 탭 껍데기 — 추후 실제 화면으로 교체
class StudentTabPlaceholderScreen extends StatelessWidget {
  const StudentTabPlaceholderScreen({
    super.key,
    required this.tabTitle,
  });

  final String tabTitle;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return ColoredBox(
      color: shell.scaffoldBackground,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tabTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: shell.titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '준비 중입니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: shell.hintColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
