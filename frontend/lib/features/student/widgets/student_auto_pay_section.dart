import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_wallet_provider.dart';
import 'package:ieum/features/student/widgets/student_card_registration_form.dart';

class StudentAutoPaySection extends ConsumerWidget {
  const StudentAutoPaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ShellTheme.of(context);

    return _CardPaymentBlock(shell: shell);
  }
}

class _CardPaymentBlock extends StatelessWidget {
  const _CardPaymentBlock({required this.shell});

  final ShellTheme shell;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: shell.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.studentInk, width: 1.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.studentPoint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    size: 22,
                    color: AppColors.studentInk,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AutoPayMethod.card.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: shell.titleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '카드 정보 입력 후 충전',
                        style: TextStyle(
                          fontSize: 12,
                          color: shell.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: shell.dividerColor),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: StudentCardRegistrationForm(prefillFromWallet: false),
          ),
        ],
      ),
    );
  }
}
