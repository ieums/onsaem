import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/utils/phone_input_formatter.dart';
import 'package:ieum/core/widgets/profile_image.dart';
import 'package:ieum/core/widgets/shell_filter_chip.dart';
import 'package:ieum/features/student/providers/mypage_provider.dart';
import 'package:ieum/features/tutor/widgets/tutor_action_button_style.dart';

class TutorProfileEditScreen extends ConsumerStatefulWidget {
  const TutorProfileEditScreen({super.key});

  @override
  ConsumerState<TutorProfileEditScreen> createState() =>
      _TutorProfileEditScreenState();
}

class _TutorProfileEditScreenState
    extends ConsumerState<TutorProfileEditScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  String _email = '';
  String? _imageUrl;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  final List<String> _selectedSubjects = [];

  static const _subjectOptions = [
    'MATH', 'KOREAN', 'ENGLISH', 'SCIENCE', 'SOCIAL'
  ];
  static const _subjectLabels = {
    'MATH': '수학',
    'KOREAN': '국어',
    'ENGLISH': '영어',
    'SCIENCE': '과학',
    'SOCIAL': '사회',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await ref.read(mypageRepositoryProvider).getMe();
      _name.text = (me['name'] as String?) ?? '';
      _email = (me['email'] as String?) ?? '';
      _phone.text = formatPhoneNumber((me['phone'] as String?) ?? '');
      _bio.text = (me['bio'] as String?) ?? '';
      _imageUrl = me['profileImageUrl'] as String?;
      final subjects = (me['subjects'] as List?)?.cast<String>() ?? [];
      setState(() => _selectedSubjects.addAll(subjects));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// 프로필 이미지 변경 — 기본 이미지 / 갤러리 선택. (학생 화면과 동일)
  Future<void> _chooseProfileImage() async {
    final hasImage = _imageUrl != null && _imageUrl!.isNotEmpty;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('기본 이미지 사용'),
                onTap: () => Navigator.pop(ctx, 'default'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'default') {
      await _resetToDefaultImage();
    } else if (choice == 'gallery') {
      await _pickAndUploadImage();
    }
  }

  /// 기본 이미지로 되돌리기 — 서버에 저장된 프로필 이미지를 비운다(PATCH profileImageUrl='').
  Future<void> _resetToDefaultImage() async {
    setState(() => _uploadingImage = true);
    try {
      await ref
          .read(mypageRepositoryProvider)
          .updateProfile(profileImageUrl: '');
      if (!mounted) return;
      setState(() {
        _imageUrl = null;
        _uploadingImage = false;
      });
      ref.invalidate(meProvider);
      _snack('기본 이미지로 변경했어요.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      _snack('변경에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref
          .read(mypageRepositoryProvider)
          .uploadProfileImage(bytes, filename: picked.name);
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _uploadingImage = false;
      });
      ref.invalidate(meProvider);
      _snack('프로필 사진이 변경됐어요.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      _snack('사진 업로드에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _snack('이름을 입력해 주세요.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(mypageRepositoryProvider).updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim().isNotEmpty ? _phone.text.trim() : null,
            bio: _bio.text.trim(),
            subjects: List<String>.from(_selectedSubjects),
          );
      if (!mounted) return;
      ref.invalidate(meProvider);
      _snack('프로필이 수정됐어요.');
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('수정에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final theme =
        (isDark ? AppTheme.shellDark : AppTheme.shellLight).copyWith(
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.tutorScaffoldLight,
    );
    return Theme(
      data: theme,
      child: Builder(builder: (context) {
        final shell = ShellTheme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('프로필 수정',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryBlue))
              : SafeArea(
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _buildAvatar(shell),
                      const SizedBox(height: 28),
                      _label(shell, '이름'),
                      _field(shell, _name, '이름'),
                      const SizedBox(height: 20),
                      _label(shell, '전화번호'),
                      _field(shell, _phone, '010-0000-0000',
                          keyboard: TextInputType.phone,
                          inputFormatters: const [PhoneInputFormatter()]),
                      const SizedBox(height: 20),
                      _label(shell, '이메일 (변경 불가)'),
                      _readonlyBox(shell,
                          _email.isEmpty ? '-' : _email),
                      const SizedBox(height: 20),
                      _label(shell, '한줄 소개'),
                      _field(shell, _bio, '나를 소개해 주세요',
                          maxLines: 3),
                      const SizedBox(height: 20),
                      _label(shell, '담당 과목'),
                      _buildSubjectChips(),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 52,
                        // 통일 스타일: 테두리만 특징색 + 흰/다크 내부 + 검정/특징색 글씨.
                        child: OutlinedButton(
                          onPressed: _saving ? null : _save,
                          style: tutorOutlinedButtonStyle(
                            isDark,
                            radius: 14,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: AppColors.primaryBlue))
                              : const Text('저장',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      }),
    );
  }

  Widget _buildAvatar(ShellTheme shell) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = _imageUrl;
    final resolved = (url != null && url.isNotEmpty)
        ? ApiConstants.resolveImageUrl(url)
        : null;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor:
                AppColors.primaryBlue.withValues(alpha: 0.15),
            backgroundImage:
                resolved != null ? NetworkImage(resolved) : null,
            child: _uploadingImage
                ? const CircularProgressIndicator(
                    color: AppColors.primaryBlue, strokeWidth: 2.6)
                : (resolved == null
                    // 기본 이미지로 되돌렸을 때 역할별(강사) 기본 프로필 표시
                    ? const ClipOval(
                        child: DefaultProfileImage(
                          role: ProfileRole.tutor,
                          size: 96,
                          iconColor: AppColors.primaryBlue,
                        ),
                      )
                    : null),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            // 통일 스타일: 테두리만 특징색 + 흰/다크 내부 + 검정/특징색 아이콘.
            child: Material(
              color: isDark ? AppColors.shellSurfaceDark : Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap:
                    _uploadingImage ? null : _chooseProfileImage,
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 16,
                      color: isDark ? AppColors.primaryBlue : Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 담당 과목 — 강사 신청 리스트의 '선별 과목 태그'(ShellFilterChip)와 디자인 통일.
  Widget _buildSubjectChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _subjectOptions.map((code) {
        final selected = _selectedSubjects.contains(code);
        return ShellFilterChip(
          label: _subjectLabels[code]!,
          selected: selected,
          onTap: () => setState(() {
            if (selected) {
              _selectedSubjects.remove(code);
            } else {
              _selectedSubjects.add(code);
            }
          }),
        );
      }).toList(),
    );
  }

  Widget _readonlyBox(ShellTheme shell, String text) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: shell.detailBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style:
                TextStyle(fontSize: 15, color: shell.hintColor)),
      );

  Widget _label(ShellTheme shell, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: shell.subtitleColor)),
      );

  Widget _field(
    ShellTheme shell,
    TextEditingController c,
    String hint, {
    TextInputType? keyboard,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          BorderSide(color: shell.cardBorder.withValues(alpha: 0.5)),
    );
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 15, color: shell.titleColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: shell.cardBackground,
        hintText: hint,
        hintStyle: TextStyle(color: shell.hintColor),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.primaryBlue, width: 1.6),
        ),
      ),
    );
  }
}
