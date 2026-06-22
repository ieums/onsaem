import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_wallet_provider.dart';
import 'package:ieum/features/student/widgets/student_payment_checkout_sheet.dart';
import 'package:ieum/features/student/widgets/student_recharge_payment_section.dart';

class StudentCreditRechargeScreen extends ConsumerStatefulWidget {
  const StudentCreditRechargeScreen({super.key});

  @override
  ConsumerState<StudentCreditRechargeScreen> createState() =>
      _StudentCreditRechargeScreenState();
}

class _StudentCreditRechargeScreenState
    extends ConsumerState<StudentCreditRechargeScreen> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(studentWalletProvider);
    final packages = StudentWalletNotifier.rechargePackages;
    final selected = packages[_selectedIndex];

    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (themedContext) {
          final shell = ShellTheme.of(themedContext);
          final pageBg = Theme.of(themedContext).scaffoldBackgroundColor;

          return Scaffold(
            backgroundColor: pageBg,
            appBar: AppBar(
              backgroundColor: pageBg,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: shell.titleColor,
                ),
                onPressed: () => themedContext.pop(),
              ),
              title: Text(
                '크레딧 충전',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: shell.titleColor,
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBalanceCard(wallet.balance),
                        const SizedBox(height: 22),
                        _buildSectionTitle(shell, '충전 금액 선택'),
                        const SizedBox(height: 10),
                        for (var i = 0; i < packages.length; i++) ...[
                          _buildPackageCard(
                            shell: shell,
                            isDark: isDark,
                            package: packages[i],
                            selected: _selectedIndex == i,
                            onTap: () => setState(() => _selectedIndex = i),
                          ),
                          if (i < packages.length - 1) const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 22),
                        _buildSectionTitle(shell, '결제 수단'),
                        const SizedBox(height: 10),
                        const StudentRechargePaymentSection(),
                      ],
                    ),
                  ),
                ),
                ColoredBox(
                  color: pageBg,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () => showStudentPaymentCheckoutSheet(
                            themedContext,
                            ref,
                            package: selected,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.studentPoint,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '${formatCredits(selected.price)}원 결제하기',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ShellTheme shell, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: shell.titleColor,
      ),
    );
  }

  Widget _buildBalanceCard(int balance) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.studentPoint,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.studentPoint.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 보유 크레딧',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatCredits(balance)} P',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required ShellTheme shell,
    required bool isDark,
    required RechargePackage package,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: shell.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.studentPoint : shell.cardBorder,
          width: selected ? 1.8 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${formatCredits(package.totalPoints)}P',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: shell.titleColor,
                          ),
                        ),
                        if (package.bonusPoints > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '+${formatCredits(package.bonusPoints)}P',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.incomeGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${formatCredits(package.price)}원',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: shell.hintColor,
                          ),
                        ),
                        if (package.isBest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.studentPoint.withValues(alpha: 0.2)
                                  : const Color(0xFFE8F2FB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'BEST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.studentPoint,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.studentPoint : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.studentPoint : shell.cardBorder,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
