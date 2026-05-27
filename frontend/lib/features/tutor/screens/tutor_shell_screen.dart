import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/app_shell_tab_bar.dart';
import 'package:ieum/features/tutor/screens/tutor_home_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_my_page_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_request_list_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_settlement_screen.dart';

/// 강사 탭: 홈 · 신청리스트 · 정산 · 마이페이지
class TutorShellScreen extends ConsumerStatefulWidget {
  const TutorShellScreen({super.key});

  @override
  ConsumerState<TutorShellScreen> createState() => _TutorShellScreenState();
}

class _TutorShellScreenState extends ConsumerState<TutorShellScreen> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
    (icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt, label: '신청리스트'),
    (
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: '정산',
    ),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이페이지'),
  ];

  static final _screens = [
    TutorHomeScreen(),
    TutorRequestListScreen(),
    TutorSettlementScreen(),
    TutorMyPageScreen(),
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
