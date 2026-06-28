import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/tutor/providers/settlement_provider.dart';

/// 정산 계좌 등록·수정 다이얼로그(강사 공용).
/// 마이페이지/정산 화면 어디서든 호출 가능. 저장 성공 시 true 반환.
Future<bool> showSettlementAccountDialog(
    BuildContext context, WidgetRef ref) async {
  final repo = ref.read(settlementRepositoryProvider);

  // 현재 등록된 계좌를 먼저 불러와 미리 채운다(미등록이면 빈 값).
  String initialBank = _bankOptions.first;
  String initialAccount = '';
  String initialHolder = '';
  try {
    final acc = await repo.fetchAccount();
    if (acc.bank != null && _bankOptions.contains(acc.bank)) {
      initialBank = acc.bank!;
    }
    initialAccount = acc.account ?? '';
    initialHolder = acc.holder ?? '';
  } catch (_) {
    // 미등록/네트워크 오류 → 빈 값으로 시작.
  }
  if (!context.mounted) return false;

  final accountController = TextEditingController(text: initialAccount);
  final holderController = TextEditingController(text: initialHolder);
  var selectedBank = initialBank;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final shell = ShellTheme.of(dialogContext);
      final scheme = Theme.of(dialogContext).colorScheme;
      final width = MediaQuery.sizeOf(dialogContext).width * 0.92;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: scheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('정산 계좌 관리',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: shell.titleColor)),
                    const SizedBox(height: 6),
                    Text('입금받을 본인 명의 계좌만 등록할 수 있습니다.',
                        style:
                            TextStyle(fontSize: 13, color: shell.hintColor)),
                    const SizedBox(height: 16),
                    _bankSelectField(
                      shell,
                      selectedBank: selectedBank,
                      onTap: () => _showBankPickerSheet(
                        dialogContext,
                        shell,
                        selectedBank: selectedBank,
                        onSelected: (bank) =>
                            setDialogState(() => selectedBank = bank),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _accountField(shell,
                        label: '계좌번호', controller: accountController),
                    const SizedBox(height: 10),
                    _accountField(shell,
                        label: '예금주', controller: holderController),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              side: BorderSide(color: shell.borderColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final bank = selectedBank;
                              final account = accountController.text.trim();
                              final holder = holderController.text.trim();
                              final messenger =
                                  ScaffoldMessenger.of(dialogContext);
                              final navigator = Navigator.of(dialogContext);
                              try {
                                await repo.updateAccount(
                                  bank: bank,
                                  account: account,
                                  holder: holder,
                                );
                                navigator.pop(true);
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('정산 계좌가 저장되었습니다.')),
                                );
                              } on DioException catch (e) {
                                // 백엔드 형식 검증 메시지(계좌번호 8~20자리 등)를 그대로 노출.
                                final data = e.response?.data;
                                final msg = data is Map<String, dynamic>
                                    ? data['message'] as String?
                                    : null;
                                messenger.showSnackBar(
                                  SnackBar(
                                      content: Text(msg ??
                                          '저장에 실패했어요. 잠시 후 다시 시도해 주세요.')),
                                );
                              } catch (_) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          '저장에 실패했어요. 잠시 후 다시 시도해 주세요.')),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('저장'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  accountController.dispose();
  holderController.dispose();
  return saved ?? false;
}

const _bankOptions = [
  '국민은행', '신한은행', '하나은행', '우리은행', 'NH농협은행',
  '카카오뱅크', '토스뱅크', '케이뱅크', 'IBK기업은행', '새마을금고',
  '신협', 'SC제일은행', '수협은행', '우체국', '대구은행',
  '부산은행', '경남은행', '광주은행', '전북은행', '제주은행',
];

Widget _bankSelectField(ShellTheme shell,
    {required String selectedBank, required VoidCallback onTap}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('은행',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: shell.subtitleColor)),
      const SizedBox(height: 6),
      Material(
        color: shell.scaffoldBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: shell.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(selectedBank,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: shell.titleColor)),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: shell.hintColor),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

void _showBankPickerSheet(
  BuildContext context,
  ShellTheme shell, {
  required String selectedBank,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      final maxH = MediaQuery.sizeOf(sheetContext).height * 0.55;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text('은행 선택',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor)),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
                itemCount: _bankOptions.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: shell.dividerColor),
                itemBuilder: (_, index) {
                  final bank = _bankOptions[index];
                  final selected = bank == selectedBank;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(bank,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? AppColors.primaryBlue
                                : shell.titleColor)),
                    trailing: selected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primaryBlue)
                        : null,
                    onTap: () {
                      onSelected(bank);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _accountField(ShellTheme shell,
    {required String label, required TextEditingController controller}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: shell.subtitleColor)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: shell.scaffoldBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: shell.borderColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: shell.borderColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryBlue)),
        ),
      ),
    ],
  );
}
