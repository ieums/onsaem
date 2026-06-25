import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/features/auth/data/auth_controller.dart';
import 'package:ieum/features/auth/utils/password_rules.dart';
import 'package:ieum/core/network/api_error.dart';

class StudentSignupScreen extends ConsumerStatefulWidget {
  const StudentSignupScreen({
    super.key,
    this.isEditMode = false,
  });

  final bool isEditMode;

  @override
  ConsumerState<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends ConsumerState<StudentSignupScreen> {
  static const _backgroundColor = Color(0xFFF8F9FD);
  static const _inputFillColor = Color(0xFFEEF1F7);
  static const _hintColor = Color(0xFF9AA3B2);
  static const _labelColor = Color(0xFF1A1D26);
  static const _errorColor = Color(0xFFE53935);
  static const _profilePlaceholderColor = Color(0xFFC5CAD3);
  static const _profileSize = 96.0;
  static const _profileAddButtonSize = 24.0;

  static const _domainOptions = ['직접입력', 'gmail.com', 'naver.com'];
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
  Uint8List? _profileImageBytes;
  bool _isSubmitting = false; 

  bool get _isShellThemed => widget.isEditMode;

  ThemeData? get _shellTheme {
    if (!_isShellThemed) return null;
    final base =
        ref.watch(shellDarkModeProvider) ? AppTheme.shellDark : AppTheme.shellLight;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: AppColors.studentInk),
    );
  }

  Color _scaffoldBg(BuildContext context) => _isShellThemed
      ? Theme.of(context).scaffoldBackgroundColor
      : _backgroundColor;

  Color _textPrimary(BuildContext context) =>
      _isShellThemed ? Theme.of(context).colorScheme.onSurface : _labelColor;

  Color _textHint(BuildContext context) => _isShellThemed
      ? Theme.of(context).colorScheme.onSurfaceVariant
      : _hintColor;

  Color _fieldFill(BuildContext context) {
    if (!_isShellThemed) return _inputFillColor;
    if (_isShellDark(context)) {
      return Theme.of(context).inputDecorationTheme.fillColor ??
          Theme.of(context).colorScheme.surface;
    }
    return const Color(0xFFF0F2F7);
  }

  Color _profilePlaceholder(BuildContext context) {
    if (!_isShellThemed) return _profilePlaceholderColor;
    if (_isShellDark(context)) {
      return Theme.of(context).colorScheme.surfaceContainerHigh;
    }
    return const Color(0xFFF0F2F7);
  }

  Color _menuSurface(BuildContext context) => _isShellThemed
      ? (_isShellDark(context)
          ? Theme.of(context).colorScheme.surface
          : Colors.white)
      : Colors.white;

  Color _selectorFieldFill(BuildContext context) =>
      _isShellDark(context) ? _scheme(context).surface : _fieldFill(context);

  Color _selectorRowFill(BuildContext context, {required bool selected}) {
    if (selected) return AppColors.studentInk;
    if (_isShellDark(context)) return _scheme(context).surface;
    return _isShellThemed ? _menuSurface(context) : Colors.white;
  }

  Color _selectorLabelColor(BuildContext context, {required bool selected}) {
    if (selected) {
      return AppColors.onPrimaryFill(Theme.of(context).brightness);
    }
    return _textPrimary(context);
  }

  Color _selectorIconColor(BuildContext context, {required bool isOpen}) {
    if (isOpen) return AppColors.studentInk;
    if (_isShellDark(context)) return AppColors.white70;
    return _textHint(context);
  }

  bool _isShellDark(BuildContext context) =>
      _isShellThemed && Theme.of(context).brightness == Brightness.dark;

  ColorScheme _scheme(BuildContext context) => Theme.of(context).colorScheme;

  Color _accentFill(BuildContext context) {
    if (!_isShellThemed) return AppColors.studentInk;
    if (_isShellDark(context)) return _scheme(context).surfaceContainerHigh;
    return _scheme(context).primary;
  }

  Color _accentForeground(BuildContext context) {
    if (!_isShellThemed) return Colors.white;
    if (_isShellDark(context)) return _scheme(context).primary;
    return _scheme(context).onPrimary;
  }

  Color _profileAddBorder(BuildContext context) {
    if (!_isShellThemed) return Colors.white;
    return _scaffoldBg(context);
  }

  ButtonStyle _primaryCtaStyle(BuildContext context) {
    if (_isShellDark(context)) {
      return FilledButton.styleFrom(
        backgroundColor: _scheme(context).surface,
        foregroundColor: _scheme(context).onSurface,
        disabledBackgroundColor: _scheme(context).surfaceContainerLow,
        disabledForegroundColor: _scheme(context).onSurfaceVariant,
        elevation: 0,
        side: BorderSide(color: _scheme(context).primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
    }
    return FilledButton.styleFrom(
      backgroundColor:
          _isShellThemed ? _scheme(context).primary : AppColors.studentInk,
      foregroundColor:
          _isShellThemed ? _scheme(context).onPrimary : Colors.white,
      disabledBackgroundColor: AppColors.studentPoint.withValues(alpha: 0.4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Color _focusBorderColor(BuildContext context) =>
      _isShellThemed ? _scheme(context).primary : AppColors.studentInk;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _nameController.text = '테스트';
      _yearController.text = '2008';
      _monthController.text = '03';
      _dayController.text = '15';
      _emailLocalController.text = 'student';
      _phoneController.text = '010-1234-5678';
    }
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
    final shellTheme = _shellTheme;

    _domainOverlayEntry?.remove();
    _domainOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        Widget buildMenuStack(BuildContext menuContext) {
          return Stack(
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
                child: _buildDomainMenu(menuContext),
              ),
            ],
          );
        }

        if (shellTheme != null) {
          return Theme(
            data: shellTheme,
            child: Builder(builder: buildMenuStack),
          );
        }
        return buildMenuStack(overlayContext);
      },
    );

    Overlay.of(context).insert(_domainOverlayEntry!);
  }

  void _validatePasswordMatch() {
    // 비밀번호 규칙 체크리스트도 함께 실시간 갱신되도록 매 입력마다 rebuild.
    final confirm = _confirmPasswordController.text;
    final mismatch = confirm.isNotEmpty && confirm != _passwordController.text;
    setState(() => _showPasswordMismatch = mismatch);
  }

  bool get _hasProfileImage =>
      _profileImageBytes != null && _profileImageBytes!.isNotEmpty;

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) return;
      setState(() => _profileImageBytes = bytes);
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앱을 완전히 종료한 뒤 다시 실행해 주세요.')),
      );
    }
  }

    Future<void> _submit() async {
    // ── 프로필 수정 모드: 기존 동작 그대로 ──
    if (widget.isEditMode) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.studentHome);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );
      return;
    }

    // ── 신규 회원가입 ──
        // ── 신규 회원가입 ──
    final name = _nameController.text.trim();
    final emailLocal = _emailLocalController.text.trim();
    final email = _selectedDomain == '직접입력'
        ? emailLocal
        : '$emailLocal@$_selectedDomain';
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final year = _yearController.text.trim();
    final month = _monthController.text.trim();
    final day = _dayController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('이름·이메일·비밀번호를 모두 입력해주세요.');
      return;
    }
    if (year.length != 4 || month.isEmpty || day.isEmpty) {
      _showSnack('생년월일을 정확히 입력해주세요.');
      return;
    }
    if (phone.isEmpty) {
      _showSnack('휴대폰 번호를 입력해주세요.');
      return;
    }
    final pwError = passwordError(password);
    if (pwError != null) {
      _showSnack(pwError);
      return;
    }
    if (password != confirm) {
      setState(() => _showPasswordMismatch = true);
      return;
    }

    // 백엔드 LocalDate 형식 "yyyy-MM-dd" 로 조합 (월·일 zero-pad)
    final birthDate =
        '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider).studentSignup(
            email: email,
            password: password,
            name: name,
            birthDate: birthDate,
            phone: phone,
          );
      if (!mounted) return;
      context.go(RoutePaths.studentHome);
    } catch (e) {
      if (!mounted) return;
      _showSnack(apiErrorMessage(e, fallback: '회원가입에 실패했어요. 이미 가입된 이메일인지 확인해주세요.'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = Builder(builder: _buildScreen);
    final theme = _shellTheme;
    if (theme != null) {
      return Theme(data: theme, child: screen);
    }
    return screen;
  }

  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: _scaffoldBg(context),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: _textPrimary(context)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                widget.isEditMode ? RoutePaths.studentHome : RoutePaths.signup,
              );
            }
          },
        ),
        title: Text(
          widget.isEditMode ? '프로필 수정' : '학생 회원가입',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textPrimary(context),
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
                  _buildProfilePhotoSection(context),
                  const SizedBox(height: 24),
                  _buildLabel(context, '이름'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context,
                    controller: _nameController,
                    hint: '이름을 입력하세요',
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(context, '생년월일'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          context,
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
                          context,
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
                          context,
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
                  _buildLabel(context, '이메일'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          context,
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
                        child: _buildDomainTrigger(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(context, '휴대폰'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context,
                    controller: _phoneController,
                    hint: '전화번호를 입력하세요',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _PhoneNumberFormatter(),
                    ],
                  ),
                  if (!widget.isEditMode) ...[
                    const SizedBox(height: 20),
                    _buildLabel(context, '비밀번호'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      context,
                      controller: _passwordController,
                      hint: '비밀번호를 입력하세요',
                      obscureText: _obscurePassword,
                      suffixIcon: _buildVisibilityToggle(
                        context,
                        isVisible: _obscurePassword,
                        onToggle: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PasswordRulesChecklist(
                      password: _passwordController.text,
                      compact: true,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel(context, '비밀번호 확인'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      context,
                      controller: _confirmPasswordController,
                      hint: '비밀번호를 다시 입력하세요',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: _buildVisibilityToggle(
                        context,
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
                onPressed: _isSubmitting ? null : _submit,
                style: _primaryCtaStyle(context),
                child: Text(
                  widget.isEditMode ? '저장하기' : '가입하기',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _isShellDark(context)
                        ? _scheme(context).onSurface
                        : (_isShellThemed
                            ? _scheme(context).onPrimary
                            : Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textPrimary(context),
      ),
    );
  }

  Widget _buildProfilePhotoSection(BuildContext context) {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: _profileSize,
            height: _profileSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  behavior: HitTestBehavior.opaque,
                  child: _buildProfileAvatar(context),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: _profileAddButtonSize,
                      height: _profileAddButtonSize,
                      decoration: BoxDecoration(
                        color: _accentFill(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _profileAddBorder(context),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: _accentForeground(context),
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.isEditMode ? '프로필 수정' : '프로필 등록',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textHint(context),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return Container(
      width: _profileSize,
      height: _profileSize,
      decoration: BoxDecoration(
        color: _profilePlaceholder(context),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: _hasProfileImage
            ? Image.memory(
                _profileImageBytes!,
                width: _profileSize,
                height: _profileSize,
                fit: BoxFit.cover,
              )
            : Center(
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: _isShellThemed
                      ? _textHint(context)
                      : Colors.white,
                ),
              ),
      ),
    );
  }

  double get _domainBoxWidth {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var maxText = 0.0;
    for (final domain in _presetDomainsForWidth) {
      for (final weight in [FontWeight.w500, FontWeight.w600]) {
        painter.text = TextSpan(
          text: _domainLabel(domain),
          style: _domainTextStyle.copyWith(fontWeight: weight),
        );
        painter.layout();
        maxText = math.max(maxText, painter.width);
      }
    }
    const horizontalPadding = 24.0;
    const iconAndGap = 26.0;
    const safetyBuffer = 8.0;
    return maxText + horizontalPadding + iconAndGap + safetyBuffer;
  }

  /// 도메인 표시 라벨 — 실제 도메인은 앞에 '@'를 붙여 보여준다('@gmail.com').
  /// '직접입력'은 모드 라벨이라 그대로.
  String _domainLabel(String domain) =>
      domain == '직접입력' ? domain : '@$domain';

  Widget _buildDomainTrigger(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleDomainMenu,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: _selectorFieldFill(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _domainLabel(_selectedDomain),
                  style: _domainTextStyle.copyWith(color: _textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isDomainMenuOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _selectorIconColor(context, isOpen: _isDomainMenuOpen),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainMenu(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          for (final domain in _domainOptions) _buildDomainMenuItem(context, domain),
        ],
      ),
    );
  }

  Widget _buildDomainMenuItem(BuildContext context, String domain) {
    final isSelected = domain == _selectedDomain;
    return SizedBox(
      width: _domainBoxWidth,
      child: Material(
        color: _selectorRowFill(context, selected: isSelected),
        child: InkWell(
          onTap: () {
            setState(() => _selectedDomain = domain);
            _closeDomainMenu();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Text(
              _domainLabel(domain),
              style: _domainTextStyle.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: _selectorLabelColor(context, selected: isSelected),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle(
    BuildContext context, {
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: _textHint(context),
        size: 22,
      ),
      onPressed: onToggle,
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    TextAlign textAlign = TextAlign.start,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      onChanged: onChanged,
      style: TextStyle(fontSize: 16, color: _textPrimary(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textHint(context), fontSize: 15),
        filled: true,
        fillColor: _fieldFill(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
          borderSide: BorderSide(color: _focusBorderColor(context), width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

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
