import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_wallet_provider.dart';

const studentCardCompanyPlaceholder = '카드사를 선택해주세요';

const studentCardCompanyOptions = [
  '신한카드',
  'KB국민카드',
  '삼성카드',
  '현대카드',
  '롯데카드',
  '우리카드',
  '하나카드',
  'NH농협카드',
  'BC카드',
];

void showStudentCardCompanyPicker(
  BuildContext context, {
  required ShellTheme shell,
  String? selectedCompany,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final sheetShell = ShellTheme.of(sheetContext);
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
            Text(
              '카드사 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: sheetShell.titleColor,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
                itemCount: studentCardCompanyOptions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: sheetShell.dividerColor,
                ),
                itemBuilder: (_, index) {
                  final company = studentCardCompanyOptions[index];
                  final selected =
                      selectedCompany != null && company == selectedCompany;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      company,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.studentPoint
                            : sheetShell.titleColor,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.studentPoint,
                          )
                        : null,
                    onTap: () {
                      onSelected(company);
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

class StudentCardRegistrationForm extends ConsumerStatefulWidget {
  const StudentCardRegistrationForm({
    super.key,
    this.onSaved,
    this.showSaveButton = true,
    this.prefillFromWallet = true,
  });

  final VoidCallback? onSaved;
  final bool showSaveButton;
  final bool prefillFromWallet;

  @override
  ConsumerState<StudentCardRegistrationForm> createState() =>
      _StudentCardRegistrationFormState();
}

class _StudentCardRegistrationFormState
    extends ConsumerState<StudentCardRegistrationForm> {
  late final TextEditingController _numberController;
  late final TextEditingController _expiryController;
  late final TextEditingController _holderController;
  String? _selectedCompany;

  @override
  void initState() {
    super.initState();
    final wallet = ref.read(studentWalletProvider);
    _numberController = TextEditingController(
      text: widget.prefillFromWallet ? wallet.cardNumber : '',
    );
    _expiryController = TextEditingController(
      text: widget.prefillFromWallet ? wallet.cardExpiry : '',
    );
    _holderController = TextEditingController(
      text: widget.prefillFromWallet ? wallet.cardHolder : '',
    );
    _selectedCompany = widget.prefillFromWallet &&
            studentCardCompanyOptions.contains(wallet.cardCompany)
        ? wallet.cardCompany
        : null;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  void _save() {
    final company = _selectedCompany;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(studentCardCompanyPlaceholder)),
      );
      return;
    }
    ref.read(studentWalletProvider.notifier).updatePaymentMethod(
          cardCompany: company,
          cardNumber: _numberController.text.trim(),
          cardExpiry: _expiryController.text.trim(),
          cardHolder: _holderController.text.trim(),
        );
    widget.onSaved?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('카드가 등록되었습니다.')),
    );
  }

  Color _fieldFill(BuildContext context, ShellTheme shell) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? shell.detailBackground : const Color(0xFFF7F8FA);
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final fieldFill = _fieldFill(context, shell);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardFormSelectField(
          shell: shell,
          fillColor: fieldFill,
          label: '카드사',
          value: _selectedCompany ?? studentCardCompanyPlaceholder,
          isPlaceholder: _selectedCompany == null,
          onTap: () => showStudentCardCompanyPicker(
            context,
            shell: shell,
            selectedCompany: _selectedCompany,
            onSelected: (company) => setState(() => _selectedCompany = company),
          ),
        ),
        const SizedBox(height: 10),
        _CardFormInputField(
          shell: shell,
          fillColor: fieldFill,
          label: '카드번호',
          controller: _numberController,
          keyboardType: TextInputType.number,
          hint: '0000-0000-0000-0000',
        ),
        const SizedBox(height: 10),
        _CardFormInputField(
          shell: shell,
          fillColor: fieldFill,
          label: '유효기간',
          controller: _expiryController,
          keyboardType: TextInputType.number,
          hint: 'MM/YY',
        ),
        const SizedBox(height: 10),
        _CardFormInputField(
          shell: shell,
          fillColor: fieldFill,
          label: '카드 소유자',
          controller: _holderController,
          hint: '이름을 입력하세요',
        ),
        if (widget.showSaveButton) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.studentPoint,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '카드 저장',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CardFormSelectField extends StatelessWidget {
  const _CardFormSelectField({
    required this.shell,
    required this.fillColor,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
    required this.onTap,
  });

  final ShellTheme shell;
  final Color fillColor;
  final String label;
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: shell.subtitleColor,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: shell.cardBorder),
                color: fillColor,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isPlaceholder ? shell.hintColor : shell.titleColor,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: shell.hintColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardFormInputField extends StatelessWidget {
  const _CardFormInputField({
    required this.shell,
    required this.fillColor,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
  });

  final ShellTheme shell;
  final Color fillColor;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: shell.subtitleColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 15, color: shell.titleColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: shell.hintColor, fontSize: 15),
            filled: true,
            fillColor: fillColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: shell.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: shell.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.studentPoint,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
