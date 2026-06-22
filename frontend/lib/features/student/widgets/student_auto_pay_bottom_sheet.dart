import 'package:flutter/material.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/widgets/student_auto_pay_section.dart';
import 'package:ieum/features/student/widgets/student_payment_history_bottom_sheet.dart';

void showStudentAutoPayBottomSheet(BuildContext context) {
  final shell = ShellTheme.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: shell.cardBackground,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) => const _StudentAutoPayBottomSheetBody(),
  );
}

class _StudentAutoPayBottomSheetBody extends StatefulWidget {
  const _StudentAutoPayBottomSheetBody();

  @override
  State<_StudentAutoPayBottomSheetBody> createState() =>
      _StudentAutoPayBottomSheetBodyState();
}

class _StudentAutoPayBottomSheetBodyState
    extends State<_StudentAutoPayBottomSheetBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxH = MediaQuery.sizeOf(context).height * 0.9;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 10, 12, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: shell.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '자동 결제 수단',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: shell.titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '크레딧 충전 시 사용할 결제 방법을 선택하세요.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: shell.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: shell.hintColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? shell.detailBackground : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: shell.titleColor,
                  unselectedLabelColor: shell.hintColor,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  indicator: BoxDecoration(
                    color: shell.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  tabs: const [
                    Tab(text: '결제 수단'),
                    Tab(text: '결제 내역'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  if (_tabController.index == 0) {
                    return const StudentAutoPaySection();
                  }
                  return const StudentPaymentHistoryTabPanel();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
