import 'package:flutter/material.dart';
/// 학생·강사 셸 하단 탭 바 (높이·아이콘 크기 공통)
class AppShellTabBar extends StatelessWidget {
  const AppShellTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.tabs,
  });

  static const _barHeight = 64.0;
  static const _iconSize = 24.0;
  static const _labelSize = 12.0;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<({IconData icon, IconData activeIcon, String label})> tabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barColor = Theme.of(context).navigationBarTheme.backgroundColor ??
        scheme.surface;

    return ColoredBox(
      color: barColor,
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: _barHeight,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: barColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: _labelSize,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            );
          }),
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.icon, size: _iconSize, color: scheme.onSurfaceVariant),
                selectedIcon: Icon(
                  t.activeIcon,
                  size: _iconSize,
                  color: scheme.primary,
                ),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}
