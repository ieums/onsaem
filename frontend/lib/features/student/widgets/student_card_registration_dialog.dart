import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/features/student/widgets/student_card_registration_form.dart';

void showStudentCardRegistrationDialog(BuildContext context, WidgetRef ref) {
  // 색은 다이얼로그 컨텍스트가 아니라 학생 shell 테마에서 직접 뽑는다(연보라·다크모드 어긋남 방지).
  // 내부 폼도 같은 테마를 쓰도록 Theme로 감싼다.
  final theme =
      ref.read(shellDarkModeProvider) ? AppTheme.shellDark : AppTheme.shellLight;
  final scheme = theme.colorScheme;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final width = MediaQuery.sizeOf(dialogContext).width * 0.92;
      return Theme(
        data: theme,
        child: Dialog(
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
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '자동 결제에 사용할 카드를 등록해 주세요.',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  StudentCardRegistrationForm(
                    onSaved: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
