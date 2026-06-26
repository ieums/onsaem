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
import 'package:ieum/features/student/utils/problem_enum_labels.dart';
import 'package:ieum/core/network/api_error.dart';

class TutorSignupScreen extends ConsumerStatefulWidget {
  const TutorSignupScreen({
    super.key,
    this.isEditMode = false,
  });

  final bool isEditMode;

  @override
  ConsumerState<TutorSignupScreen> createState() => _TutorSignupScreenState();
}

class _TutorSignupScreenState extends ConsumerState<TutorSignupScreen> {
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
  static const _educationOptions = ['재학', '휴학', '졸업'];
  static const _selectorTextStyle = TextStyle(
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
  final _majorController = TextEditingController();
  final _experienceController = TextEditingController();
  final _introController = TextEditingController();
  final _schoolController = TextEditingController();

  final _domainTriggerKey = GlobalKey();
  final _educationTriggerKey = GlobalKey();
  final _domainLayerLink = LayerLink();
  final _educationLayerLink = LayerLink();

  String _selectedDomain = '직접입력';
  String _selectedEducation = '재학';
  String? _proofFileName;
  Uint8List? _profileImageBytes;
  bool _isDomainMenuOpen = false;
  bool _isEducationMenuOpen = false;
  OverlayEntry? _domainOverlayEntry;
  OverlayEntry? _educationOverlayEntry;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showPasswordMismatch = false;
  int _introLength = 0;
  bool _isSubmitting = false;

  final List<String> _subjectKeywords = [];

  bool get _isShellThemed => widget.isEditMode;

  ThemeData? get _shellTheme =>
      _isShellThemed
          ? (ref.watch(shellDarkModeProvider)
              ? AppTheme.shellDark
              : AppTheme.shellLight)
          : null;

  Color _scaffoldBg(BuildContext context) => _isShellThemed
      ? Theme.of(context).scaffoldBackgroundColor
      : _backgroundColor;

  Color _textPrimary(BuildContext context) => _isShellThemed
      ? Theme.of(context).colorScheme.onSurface
      : _labelColor;

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
    if (_isShellDark(context)) return Theme.of(context).colorScheme.surfaceContainerHigh;
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
    if (selected) {
      return AppColors.primaryBlue;
    }
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
    if (isOpen) return AppColors.primaryBlue;
    if (_isShellDark(context)) return AppColors.white70;
    return _textHint(context);
  }

  bool _isShellDark(BuildContext context) =>
      _isShellThemed && Theme.of(context).brightness == Brightness.dark;

  ColorScheme _scheme(BuildContext context) => Theme.of(context).colorScheme;

  Color _accentButtonFill(BuildContext context) {
    if (!_isShellThemed) return AppColors.primaryBlue;
    if (_isShellDark(context)) return _scheme(context).surfaceContainerHigh;
    return _scheme(context).primary;
  }

  Color _accentButtonForeground(BuildContext context) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      );
    }
    return FilledButton.styleFrom(
      backgroundColor:
          _isShellThemed ? _scheme(context).primary : AppColors.primaryBlue,
      foregroundColor:
          _isShellThemed ? _scheme(context).onPrimary : Colors.white,
      disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _nameController.text = '홍길동';
      _majorController.text = '수학교육학과';
    }
    _confirmPasswordController.addListener(_validatePasswordMatch);
    _passwordController.addListener(_validatePasswordMatch);
    _introController.addListener(() {
      setState(() => _introLength = _introController.text.length);
    });
  }

  @override
  void dispose() {
    _removeAllOverlays();
    _nameController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _emailLocalController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _majorController.dispose();
    _schoolController.dispose();
    _experienceController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // ── 프로필 수정 모드: 기존 동작 보존 ──
    if (widget.isEditMode) {
      context.go(RoutePaths.tutorHome);
      return;
    }

    // ── 신규 강사 회원가입 ──
    final name = _nameController.text.trim();
    final emailLocal = _emailLocalController.text.trim();
    final email = _selectedDomain == '직접입력'
        ? emailLocal
        : '$emailLocal@$_selectedDomain';
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final major = _majorController.text.trim();
    final school = _schoolController.text.trim(); 
    final bio = _introController.text.trim();

    final year = _yearController.text.trim();
    final month = _monthController.text.trim();
    final day = _dayController.text.trim();
    final phone = _phoneController.text.trim();
    final experienceYears = int.tryParse(_experienceController.text.trim());

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
      await ref.read(authControllerProvider).tutorSignup(
            email: email,
            password: password,
            name: name,
            birthDate: birthDate,
            phone: phone,
            educationStatus: _selectedEducation,    // 재학/휴학/졸업
            subjects: _subjectKeywords,             // 과외 가능 과목
            experienceYears: experienceYears,       // 경력 연수 (선택)
            school: school.isEmpty ? null : school,  //학교
            major: major.isEmpty ? null : major,    // 전공 (선택)
            bio: bio.isEmpty ? null : bio,          // 한줄소개 (선택)
          );
      if (!mounted) return;
      context.go(RoutePaths.tutorHome); // 가입 즉시 로그인됨 → 강사 홈
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

  void _removeAllOverlays() {
    _domainOverlayEntry?.remove();
    _domainOverlayEntry = null;
    _educationOverlayEntry?.remove();
    _educationOverlayEntry = null;
  }

  void _closeDomainMenu() {
    _domainOverlayEntry?.remove();
    _domainOverlayEntry = null;
    if (mounted && _isDomainMenuOpen) {
      setState(() => _isDomainMenuOpen = false);
    }
  }

  void _closeEducationMenu() {
    _educationOverlayEntry?.remove();
    _educationOverlayEntry = null;
    if (mounted && _isEducationMenuOpen) {
      setState(() => _isEducationMenuOpen = false);
    }
  }

  void _toggleDomainMenu() {
    _closeEducationMenu();
    if (_isDomainMenuOpen) {
      _closeDomainMenu();
      return;
    }
    setState(() => _isDomainMenuOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isDomainMenuOpen) return;
      _showSelectorOverlay(
        layerLink: _domainLayerLink,
        menuWidth: _domainBoxWidth,
        menuBuilder: (menuContext) => _buildDomainMenu(menuContext),
        onInsert: (entry) => _domainOverlayEntry = entry,
        onOutsideTap: _closeDomainMenu,
      );
    });
  }

  void _toggleEducationMenu() {
    _closeDomainMenu();
    if (_isEducationMenuOpen) {
      _closeEducationMenu();
      return;
    }
    setState(() => _isEducationMenuOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isEducationMenuOpen) return;
      _showSelectorOverlay(
        layerLink: _educationLayerLink,
        menuWidth: _educationBoxWidth,
        menuBuilder: (menuContext) => _buildEducationMenu(menuContext),
        onInsert: (entry) => _educationOverlayEntry = entry,
        onOutsideTap: _closeEducationMenu,
      );
    });
  }

  void _showSelectorOverlay({
    required LayerLink layerLink,
    required double menuWidth,
    required Widget Function(BuildContext context) menuBuilder,
    required void Function(OverlayEntry entry) onInsert,
    required VoidCallback onOutsideTap,
  }) {
    final shellTheme = _shellTheme;
    final entry = OverlayEntry(
      builder: (overlayContext) {
        Widget buildMenuStack(BuildContext menuContext) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: onOutsideTap,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 8),
                child: SizedBox(
                  width: menuWidth,
                  child: menuBuilder(menuContext),
                ),
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

    onInsert(entry);
    Overlay.of(context).insert(entry);
  }

  double _measureSelectorWidth(List<String> options) {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var maxText = 0.0;
    for (final option in options) {
      for (final weight in [FontWeight.w500, FontWeight.w600]) {
        painter.text = TextSpan(
          text: option,
          style: _selectorTextStyle.copyWith(fontWeight: weight),
        );
        painter.layout();
        maxText = math.max(maxText, painter.width);
      }
    }
    return maxText + 24 + 26 + 8;
  }

  double get _domainBoxWidth =>
      _measureSelectorWidth(_presetDomainsForWidth.map(_domainLabel).toList());

  double get _educationBoxWidth => _measureSelectorWidth(_educationOptions);

  void _validatePasswordMatch() {
    // 비밀번호 규칙 체크리스트도 매 입력마다 실시간 갱신되도록 rebuild.
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
        const SnackBar(
          content: Text('앱을 완전히 종료한 뒤 다시 실행해 주세요.'),
        ),
      );
    }
  }

  Future<void> _pickProofFile() async {
    try {
      final result = await FilePicker.pickFiles();
      if (!mounted || result == null || result.files.isEmpty) return;
      final name = result.files.single.name;
      if (name.isEmpty) return;
      setState(() => _proofFileName = name);
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('앱을 완전히 종료한 뒤 다시 실행해 주세요.'),
        ),
      );
    }
  }

  /// 과외 가능 과목 — problem subject enum(미분류 제외) 다중 선택 칩.
  Widget _buildSubjectChips(BuildContext context) {
    final selectedFill = _isShellDark(context)
        ? _scheme(context).surfaceContainerHigh
        : (_isShellThemed ? _scheme(context).primary : AppColors.primaryBlue);
    final selectedFg = _accentButtonForeground(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      // subjectLabels = {KOREAN:국어, MATH:수학, ENGLISH:영어, SOCIAL:사회, SCIENCE:과학, UNKNOWN:미분류}
      // '미분류'(UNKNOWN)는 과외 가능 과목으로 고를 수 없어야 하므로 제외한다.
      // 표시는 라벨('국어'), 저장은 enum 키('KOREAN') — 학생 질문/Problem.subject와 동일한 형태로
      // 맞춰야 매칭(Subject enum 비교)이 동작한다.
      children: subjectLabels.entries
          .where((entry) => entry.key != 'UNKNOWN')
          .map((entry) {
        final code = entry.key; // 'KOREAN'
        final label = entry.value; // '국어'
        final selected = _subjectKeywords.contains(code);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            if (selected) {
              _subjectKeywords.remove(code);
            } else {
              _subjectKeywords.add(code);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? selectedFill : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : _scheme(context).outlineVariant,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? selectedFg : _scheme(context).onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDomainRow(BuildContext context) {
    return Row(
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
          child: CompositedTransformTarget(
            link: _domainLayerLink,
            child: _buildDomainTrigger(context),
          ),
        ),
      ],
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
              context.go(RoutePaths.signup);
            }
          },
        ),
        title: Text(
          widget.isEditMode ? '프로필 수정' : '강사 회원가입',
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
                  _buildDomainRow(context),
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
                  const SizedBox(height: 20),
                  _buildLabel(context, '최종학력'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: _educationBoxWidth,
                      key: _educationTriggerKey,
                      child: CompositedTransformTarget(
                        link: _educationLayerLink,
                        child: _buildEducationTrigger(context),
                      ),
                    ),
                  ),
                                    const SizedBox(height: 20),
                  _buildLabel(context, '학교'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context,
                    controller: _schoolController,
                    hint: '학교를 입력하세요',
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(context, '전공'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context,
                    controller: _majorController,
                    hint: '전공을 입력하세요',
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(context, '과외 가능 과목'),
                  const SizedBox(height: 8),
                  _buildSubjectChips(context),
                  const SizedBox(height: 20),
                  _buildLabel(context, '경력 연수'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context,
                    controller: _experienceController,
                    hint: '경력 연수를 입력해주세요',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(context, '학력 증빙 서류'),
                  const SizedBox(height: 8),
                  _buildFilePickerField(context),
                  const SizedBox(height: 20),
                  _buildLabel(context, '한줄소개'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context,
                    controller: _introController,
                    hint: '자신을 소개해주세요',
                    maxLines: 4,
                    maxLength: 50,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_introLength / 50',
                      style: TextStyle(fontSize: 12, color: _textHint(context)),
                    ),
                  ),
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
                        color: _accentButtonFill(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _profileAddBorder(context),
                          width: 2,
                        ),
                        boxShadow: _isShellDark(context)
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: _accentButtonForeground(context),
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
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Colors.white,
                ),
              ),
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

  /// 도메인 표시 라벨 — 실제 도메인은 앞에 '@'('@gmail.com'). '직접입력'은 그대로.
  String _domainLabel(String domain) =>
      domain == '직접입력' ? domain : '@$domain';

  Widget _buildDomainTrigger(BuildContext context) => _buildSelectorTrigger(
        context,
        label: _domainLabel(_selectedDomain),
        isOpen: _isDomainMenuOpen,
        onTap: _toggleDomainMenu,
      );

  Widget _buildEducationTrigger(BuildContext context) => _buildSelectorTrigger(
        context,
        label: _selectedEducation,
        isOpen: _isEducationMenuOpen,
        onTap: _toggleEducationMenu,
      );

  Widget _buildSelectorTrigger(
    BuildContext context, {
    required String label,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                  label,
                  style: _selectorTextStyle.copyWith(
                    color: _selectorLabelColor(context, selected: false),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _selectorIconColor(context, isOpen: isOpen),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainMenu(BuildContext context) => _buildSelectorMenu(
        context,
        options: _domainOptions,
        selected: _selectedDomain,
        labelOf: _domainLabel,
        onSelect: (value) {
          setState(() => _selectedDomain = value);
          _closeDomainMenu();
        },
      );

  Widget _buildEducationMenu(BuildContext context) => _buildSelectorMenu(
        context,
        options: _educationOptions,
        selected: _selectedEducation,
        onSelect: (value) {
          setState(() => _selectedEducation = value);
          _closeEducationMenu();
        },
      );

  Widget _buildSelectorMenu(
    BuildContext context, {
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
    String Function(String)? labelOf,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: options.map((option) {
          final isSelected = option == selected;
          return SizedBox(
            width: options == _domainOptions ? _domainBoxWidth : _educationBoxWidth,
            child: Material(
              color: _selectorRowFill(context, selected: isSelected),
              child: InkWell(
                onTap: () => onSelect(option),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Text(
                    labelOf == null ? option : labelOf(option),
                    style: _selectorTextStyle.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: _selectorLabelColor(context, selected: isSelected),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilePickerField(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickProofFile,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: _fieldFill(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _proofFileName ?? '파일을 선택하세요',
                  style: TextStyle(
                    fontSize: 15,
                    color: _proofFileName == null
                        ? _textHint(context)
                        : _textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.upload_file_outlined,
                color: _proofFileName == null
                    ? _textHint(context)
                    : AppColors.primaryBlue,
                size: 22,
              ),
            ],
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
    int? maxLines = 1,
    int? maxLength,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      maxLines: maxLines,
      maxLength: maxLength,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: 16, color: _textPrimary(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textHint(context), fontSize: 15),
        filled: true,
        fillColor: _fieldFill(context),
        counterText: '',
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