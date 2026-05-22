import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';

class TutorSignupScreen extends StatefulWidget {
  const TutorSignupScreen({super.key});

  @override
  State<TutorSignupScreen> createState() => _TutorSignupScreenState();
}

class _TutorSignupScreenState extends State<TutorSignupScreen> {
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
  static const _educationOptions = ['재학중', '휴학중', '반수중', '졸업함'];
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
  final _subjectInputController = TextEditingController();
  final _experienceController = TextEditingController();
  final _introController = TextEditingController();
  final _lectureStyleInputController = TextEditingController();

  final _domainTriggerKey = GlobalKey();
  final _educationTriggerKey = GlobalKey();
  final _domainLayerLink = LayerLink();
  final _educationLayerLink = LayerLink();

  String _selectedDomain = '직접입력';
  String _selectedEducation = '재학중';
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

  final List<String> _subjectKeywords = [];
  final List<String> _lectureStyleKeywords = [];

  @override
  void initState() {
    super.initState();
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
    _subjectInputController.dispose();
    _experienceController.dispose();
    _introController.dispose();
    _lectureStyleInputController.dispose();
    super.dispose();
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
        menuBuilder: _buildDomainMenu,
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
        menuBuilder: _buildEducationMenu,
        onInsert: (entry) => _educationOverlayEntry = entry,
        onOutsideTap: _closeEducationMenu,
      );
    });
  }

  void _showSelectorOverlay({
    required LayerLink layerLink,
    required double menuWidth,
    required Widget Function() menuBuilder,
    required void Function(OverlayEntry entry) onInsert,
    required VoidCallback onOutsideTap,
  }) {
    final entry = OverlayEntry(
      builder: (_) => Stack(
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
              child: menuBuilder(),
            ),
          ),
        ],
      ),
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

  double get _domainBoxWidth => _measureSelectorWidth(_presetDomainsForWidth);

  double get _educationBoxWidth => _measureSelectorWidth(_educationOptions);

  void _validatePasswordMatch() {
    final confirm = _confirmPasswordController.text;
    final mismatch = confirm.isNotEmpty && confirm != _passwordController.text;
    if (mismatch != _showPasswordMismatch) {
      setState(() => _showPasswordMismatch = mismatch);
    }
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

  void _addSubjectKeyword() {
    final value = _subjectInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _subjectKeywords.add(value);
      _subjectInputController.clear();
    });
  }

  void _addLectureStyleKeyword() {
    if (_lectureStyleKeywords.length >= 5) return;
    final value = _lectureStyleInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _lectureStyleKeywords.add(value);
      _lectureStyleInputController.clear();
    });
  }

  Widget _buildDomainRow() {
    return Row(
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
          child: CompositedTransformTarget(
            link: _domainLayerLink,
            child: _buildDomainTrigger(),
          ),
        ),
      ],
    );
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
          '강사 회원가입',
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
                  _buildProfilePhotoSection(),
                  const SizedBox(height: 24),
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
                  _buildDomainRow(),
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
                  const SizedBox(height: 20),
                  _buildLabel('최종학력'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: _educationBoxWidth,
                      key: _educationTriggerKey,
                      child: CompositedTransformTarget(
                        link: _educationLayerLink,
                        child: _buildEducationTrigger(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('전공'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _majorController,
                    hint: '전공을 입력하세요',
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('과외 가능 과목'),
                  const SizedBox(height: 8),
                  _buildKeywordInputRow(
                    controller: _subjectInputController,
                    hint: '과목 입력',
                    onAdd: _addSubjectKeyword,
                  ),
                  if (_subjectKeywords.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildKeywordWrap(
                      _subjectKeywords,
                      (keyword) =>
                          setState(() => _subjectKeywords.remove(keyword)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildLabel('경력 연수'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _experienceController,
                    hint: '경력 연수를 입력해주세요',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('학력 증빙 서류'),
                  const SizedBox(height: 8),
                  _buildFilePickerField(),
                  const SizedBox(height: 20),
                  _buildLabel('한줄소개'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _introController,
                    hint: '자신을 소개해주세요',
                    maxLines: 4,
                    maxLength: 50,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_introLength / 50',
                      style: const TextStyle(fontSize: 12, color: _hintColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('강의 스타일 소개 (최대 5개)'),
                  const SizedBox(height: 8),
                  _buildKeywordInputRow(
                    controller: _lectureStyleInputController,
                    hint: '강의 스타일 키워드',
                    onAdd: _addLectureStyleKeyword,
                    enabled: _lectureStyleKeywords.length < 5,
                  ),
                  if (_lectureStyleKeywords.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildKeywordWrap(
                      _lectureStyleKeywords,
                      (keyword) => setState(
                        () => _lectureStyleKeywords.remove(keyword),
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
                onPressed: () => context.go(RoutePaths.tutorHome),
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

  Widget _buildProfilePhotoSection() {
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
                  child: _buildProfileAvatar(),
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
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
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
        const Text(
          '프로필 등록',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: _profileSize,
      height: _profileSize,
      decoration: const BoxDecoration(
        color: _profilePlaceholderColor,
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
            : const Center(
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.white,
                ),
              ),
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

  Widget _buildDomainTrigger() => _buildSelectorTrigger(
        label: _selectedDomain,
        isOpen: _isDomainMenuOpen,
        onTap: _toggleDomainMenu,
      );

  Widget _buildEducationTrigger() => _buildSelectorTrigger(
        label: _selectedEducation,
        isOpen: _isEducationMenuOpen,
        onTap: _toggleEducationMenu,
      );

  Widget _buildSelectorTrigger({
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
            color: _inputFillColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: _selectorTextStyle.copyWith(color: _labelColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: isOpen ? AppColors.primaryBlue : _hintColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainMenu() => _buildSelectorMenu(
        options: _domainOptions,
        selected: _selectedDomain,
        onSelect: (value) {
          setState(() => _selectedDomain = value);
          _closeDomainMenu();
        },
      );

  Widget _buildEducationMenu() => _buildSelectorMenu(
        options: _educationOptions,
        selected: _selectedEducation,
        onSelect: (value) {
          setState(() => _selectedEducation = value);
          _closeEducationMenu();
        },
      );

  Widget _buildSelectorMenu({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: options.map((option) {
          final isSelected = option == selected;
          return SizedBox(
            width: options == _domainOptions ? _domainBoxWidth : _educationBoxWidth,
            child: Material(
              color: isSelected ? AppColors.primaryBlue : Colors.white,
              child: InkWell(
                onTap: () => onSelect(option),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Text(
                    option,
                    style: _selectorTextStyle.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : _labelColor,
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

  Widget _buildKeywordInputRow({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: controller,
            hint: hint,
            onSubmitted: enabled ? (_) => onAdd() : null,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          height: 48,
          child: FilledButton(
            onPressed: enabled ? onAdd : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.4),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.add, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordWrap(
    List<String> keywords,
    ValueChanged<String> onRemove,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keywords.map((keyword) {
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#$keyword',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onRemove(keyword),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilePickerField() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickProofFile,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: _inputFillColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _proofFileName ?? '파일을 선택하세요',
                  style: TextStyle(
                    fontSize: 15,
                    color: _proofFileName == null ? _hintColor : _labelColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.upload_file_outlined,
                color: _proofFileName == null ? _hintColor : AppColors.primaryBlue,
                size: 22,
              ),
            ],
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
      style: const TextStyle(fontSize: 16, color: _labelColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 15),
        filled: true,
        fillColor: _inputFillColor,
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
