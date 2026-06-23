import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_wallet_provider.dart';

void showStudentPaymentCheckoutSheet(
  BuildContext context,
  WidgetRef ref, {
  required RechargePackage package,
}) {
  final wallet = ref.read(studentWalletProvider);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final sheetShell = ShellTheme.of(sheetContext);
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final summaryBg =
          isDark ? sheetShell.detailBackground : const Color(0xFFF7F8FA);
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      final methodSubtitle = wallet.maskedCardNumber;

      return Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetShell.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '결제하기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: sheetShell.titleColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: summaryBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sheetShell.cardBorder),
              ),
              child: Column(
                children: [
                  _CheckoutRow(
                    shell: sheetShell,
                    label: '충전 크레딧',
                    value: '${formatCredits(package.totalPoints)}P',
                    valueColor: AppColors.studentInk,
                  ),
                  const SizedBox(height: 12),
                  _CheckoutRow(
                    shell: sheetShell,
                    label: '결제 금액',
                    value: '${formatCredits(package.price)}원',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: sheetShell.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sheetShell.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.credit_card_rounded,
                    size: 22,
                    color: AppColors.studentInk,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '결제 수단',
                          style: TextStyle(
                            fontSize: 12,
                            color: sheetShell.hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          methodSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: sheetShell.titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () {
                  ref.read(studentWalletProvider.notifier).recharge(package);
                  Navigator.of(sheetContext).pop();
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${formatCredits(package.totalPoints)}P가 충전되었습니다.',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.studentPoint,
                  foregroundColor: AppColors.studentInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  '${formatCredits(package.price)}원 결제하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CheckoutRow extends StatelessWidget {
  const _CheckoutRow({
    required this.shell,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final ShellTheme shell;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: shell.hintColor),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? shell.titleColor,
          ),
        ),
      ],
    );
  }
}
