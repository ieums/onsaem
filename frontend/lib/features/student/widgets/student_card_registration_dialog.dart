import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/widgets/student_card_registration_form.dart';

void showStudentCardRegistrationDialog(BuildContext context, WidgetRef ref) {
  final shell = ShellTheme.of(context);

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final width = MediaQuery.sizeOf(dialogContext).width * 0.92;
      return Dialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '카드 등록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '자동 결제에 사용할 카드를 등록해 주세요.',
                  style: TextStyle(fontSize: 13, color: shell.hintColor),
                ),
                const SizedBox(height: 16),
                StudentCardRegistrationForm(
                  onSaved: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
