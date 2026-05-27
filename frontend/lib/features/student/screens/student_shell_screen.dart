import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/app_shell_tab_bar.dart';
import 'package:ieum/features/student/screens/student_home_screen.dart';
import 'package:ieum/features/student/screens/student_lessons_screen.dart';
import 'package:ieum/features/student/screens/student_my_page_screen.dart';
import 'package:ieum/features/student/screens/student_questions_screen.dart';

/// 학생 탭: 홈 · 내 질문 · 수업 · 마이페이지
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
      icon: Icons.help_outline,
      activeIcon: Icons.help,
      label: '내 질문',
    ),
    (
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: '수업',
    ),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이페이지'),
  ];

  static final _screens = [
    StudentHomeScreen(),
    StudentQuestionsScreen(),
    StudentLessonsScreen(),
    StudentMyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);

    return Theme(
      data: isDark ? AppTheme.shellDark : AppTheme.shellLight,
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
