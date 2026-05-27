import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';

class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({super.key});

  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  static const _backgroundColor = Color(0xFFF8F9FD);
  static const _inputFillColor = Color(0xFFEEF1F7);
  static const _hintColor = Color(0xFF9AA3B2);
  static const _labelColor = Color(0xFF1A1D26);
  static const _errorColor = Color(0xFFE53935);

  static const _domainOptions = ['직접입력', 'gmail.com', 'naver.com'];
  /// 도메인 버튼 너비 — gmail/naver 기준 (직접입력은 더 짧게 보이도록 동일 폭)
  static const _presetDomainsForWidth = ['gmail.com', 'naver.com'];
  static const _domainTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();
  final _dayController = TextEditingController();
  final _emailLocalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _domainTriggerKey = GlobalKey();

  String _selectedDomain = '직접입력';
  bool _isDomainMenuOpen = false;
  OverlayEntry? _domainOverlayEntry;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showPasswordMismatch = false;

  @override
  void initState() {
    super.initState();
    _confirmPasswordController.addListener(_validatePasswordMatch);
    _passwordController.addListener(_validatePasswordMatch);
  }

  @override
  void dispose() {
    _domainOverlayEntry?.remove();
    _domainOverlayEntry = null;
    _nameController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _emailLocalController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleDomainMenu() {
    if (_isDomainMenuOpen) {
      _closeDomainMenu();
      return;
    }
    setState(() => _isDomainMenuOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isDomainMenuOpen) return;
      _showDomainOverlay();
    });
  }

  void _closeDomainMenu() {
    _domainOverlayEntry?.remove();
    _domainOverlayEntry = null;
    if (mounted && _isDomainMenuOpen) {
      setState(() => _isDomainMenuOpen = false);
    }
  }

  void _showDomainOverlay() {
    final box =
        _domainTriggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final offset = box.localToGlobal(Offset.zero);
    final triggerSize = box.size;
    final menuWidth = _domainBoxWidth;

    _domainOverlayEntry?.remove();
    _domainOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDomainMenu,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + triggerSize.height + 8,
            width: menuWidth,
            child: _buildDomainMenu(),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_domainOverlayEntry!);
  }

  void _validatePasswordMatch() {
    final confirm = _confirmPasswordController.text;
    final mismatch = confirm.isNotEmpty && confirm != _passwordController.text;
    if (mismatch != _showPasswordMismatch) {
      setState(() => _showPasswordMismatch = mismatch);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _labelColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.signup);
            }
          },
        ),
        title: const Text(
          '학생 회원가입',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _labelColor,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel('이름'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: '이름을 입력하세요',
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('생년월일'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _yearController,
                          hint: 'YYYY',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _monthController,
                          hint: 'MM',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _dayController,
                          hint: 'DD',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('이메일'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _emailLocalController,
                          hint: _selectedDomain == '직접입력'
                              ? '이메일 주소를 입력하세요'
                              : '이메일',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: _domainBoxWidth,
                        key: _domainTriggerKey,
                        child: _buildDomainTrigger(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('휴대폰'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneController,
                    hint: '전화번호를 입력하세요',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _PhoneNumberFormatter(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('비밀번호'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hint: '비밀번호를 입력하세요',
                    obscureText: _obscurePassword,
                    suffixIcon: _buildVisibilityToggle(
                      isVisible: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('비밀번호 확인'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: '비밀번호를 다시 입력하세요',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: _buildVisibilityToggle(
                      isVisible: _obscureConfirmPassword,
                      onToggle: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  if (_showPasswordMismatch) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '비밀번호가 일치하지 않습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go(RoutePaths.studentHome),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '가입하기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _labelColor,
      ),
    );
  }

  /// 가장 긴 도메인 라벨 + 패딩·아이콘 너비 (선택 버튼·메뉴 동일)
  double get _domainBoxWidth {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var maxText = 0.0;
    for (final domain in _presetDomainsForWidth) {
      for (final weight in [FontWeight.w500, FontWeight.w600]) {
        painter.text = TextSpan(
          text: domain,
          style: _domainTextStyle.copyWith(fontWeight: weight),
        );
        painter.layout();
        maxText = math.max(maxText, painter.width);
      }
    }
    const horizontalPadding = 24.0; // 12 * 2
    const iconAndGap = 26.0; // 22 + 4
    const safetyBuffer = 8.0; // 렌더링·폰트 오차 여유
    return maxText + horizontalPadding + iconAndGap + safetyBuffer;
  }

  Widget _buildDomainTrigger() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleDomainMenu,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: _inputFillColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDomain,
                  style: _domainTextStyle.copyWith(color: _labelColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isDomainMenuOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color:
                    _isDomainMenuOpen ? AppColors.primaryBlue : _hintColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 전화번호 입력창 바로 위에 표시
  Widget _buildDomainMenu() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14), // 위 버튼과 동일하게 14로 맞춤
      child: Column(
        children: [
          for (final domain in _domainOptions)
            _buildDomainMenuItem(domain),
        ],
      ),
    );
  }

  Widget _buildDomainMenuItem(String domain) {
    final isSelected = domain == _selectedDomain;
    return SizedBox(
      width: _domainBoxWidth, // 모든 도메인 메뉴 아이템의 너비를 동일하게 맞춤
      child: Material(
        color: isSelected ? AppColors.primaryBlue : Colors.white,
        child: InkWell(
          onTap: () => setState(() {
            _selectedDomain = domain;
            _isDomainMenuOpen = false;
          }),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Text(
              domain,
              style: _domainTextStyle.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : _labelColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle({
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: _hintColor,
        size: 22,
      ),
      onPressed: onToggle,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    TextAlign textAlign = TextAlign.start,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      style: const TextStyle(fontSize: 16, color: _labelColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 15),
        filled: true,
        fillColor: _inputFillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// 11자리 숫자 → 000-0000-0000 자동 포맷
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 7) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
