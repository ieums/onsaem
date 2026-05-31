import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/app_shell_tab_bar.dart';
import 'package:ieum/features/student/screens/student_home_screen.dart';
import 'package:ieum/features/student/screens/student_lessons_screen.dart';
import 'package:ieum/features/student/screens/student_my_page_screen.dart';
import 'package:ieum/features/student/screens/student_questions_screen.dart';

/// 학생 탭: 홈 · 복습 · AI튜터 · 마이페이지
class StudentShellScreen extends ConsumerStatefulWidget {
  const StudentShellScreen({super.key});

  @override
  ConsumerState<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends ConsumerState<StudentShellScreen> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
    (
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories,
      label: '복습',
    ),
    (
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy,
      label: 'AI튜터',
    ),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이페이지'),
  ];

  static final _screens = [
    StudentHomeScreen(),
    StudentLessonsScreen(),
    StudentQuestionsScreen(),
    StudentMyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: AppShellTabBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          tabs: _tabs,
        ),
      ),
    );
  }
}
