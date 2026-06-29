import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/widgets/profile_image.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/utils/phone_input_formatter.dart';
import 'package:ieum/core/widgets/role_date_picker.dart';
import 'package:ieum/features/student/providers/mypage_provider.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';

/// 프로필 수정 — PATCH /auth/me. 이름·전화·생년월일·프로필 사진 수정(이메일은 읽기전용).
class StudentProfileEditScreen extends ConsumerStatefulWidget {
  const StudentProfileEditScreen({super.key});

  @override
  ConsumerState<StudentProfileEditScreen> createState() =>
      _StudentProfileEditScreenState();
}

class _StudentProfileEditScreenState
    extends ConsumerState<StudentProfileEditScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _email = '';
  DateTime? _birthDate;
  String? _imageUrl;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;

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
      _imageUrl = (me['profileImageUrl'] as String?);
      final birth = me['birthDate'] as String?;
      if (birth != null && birth.isNotEmpty) {
        _birthDate = DateTime.tryParse(birth);
      }
    } catch (_) {
      // 프리필 실패해도 빈 폼으로 진행
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showRoleDatePicker(
      context: context,
      roleColor: AppColors.studentPoint,
      initialDate: _birthDate ?? DateTime(now.year - 16, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
      title: '생년월일',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  /// 프로필 이미지 변경 — 기본 이미지 / 갤러리 선택.
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
            phone: _phone.text.trim(),
            birthDate: _birthDate == null ? null : _fmtDate(_birthDate!),
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

  static String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.studentScaffoldLight,
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '프로필 수정',
              onBack: () => Navigator.of(context).pop(),
            ),
            body: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.studentPoint),
                  )
                : SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                        _label(shell, '생년월일'),
                        _buildBirthField(shell),
                        const SizedBox(height: 20),
                        _label(shell, '이메일 (변경 불가)'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: shell.detailBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _email.isEmpty ? '-' : _email,
                            style: TextStyle(
                                fontSize: 15, color: shell.hintColor),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.studentPoint,
                              foregroundColor: Colors.black, // 연두 위 글씨 검정
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4, color: Colors.black),
                                  )
                                : const Text('저장',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(ShellTheme shell) {
    final url = _imageUrl;
    final resolved = (url != null && url.isNotEmpty)
        ? ApiConstants.resolveImageUrl(url)
        : null;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.roleStudentBorder.withValues(alpha: 0.35),
            backgroundImage:
                resolved != null ? NetworkImage(resolved) : null,
            child: _uploadingImage
                ? const CircularProgressIndicator(
                    color: AppColors.studentPoint, strokeWidth: 2.6)
                : (resolved == null
                    ? const ClipOval(
                        child: DefaultProfileImage(
                          role: ProfileRole.student,
                          size: 96,
                          iconColor: AppColors.studentPoint,
                        ),
                      )
                    : null),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.studentPoint,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploadingImage ? null : _chooseProfileImage,
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 16, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthField(ShellTheme shell) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: shell.cardBorder.withValues(alpha: 0.5)),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickBirthDate,
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: shell.cardBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: border,
          enabledBorder: border,
          suffixIcon: Icon(Icons.calendar_today_rounded,
              size: 18, color: shell.hintColor),
        ),
        child: Text(
          _birthDate == null ? '생년월일 선택' : _fmtDate(_birthDate!),
          style: TextStyle(
            fontSize: 15,
            color: _birthDate == null ? shell.hintColor : shell.titleColor,
          ),
        ),
      ),
    );
  }

  Widget _label(ShellTheme shell, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: shell.subtitleColor)),
      );

  Widget _field(ShellTheme shell, TextEditingController c, String hint,
      {TextInputType? keyboard, List<TextInputFormatter>? inputFormatters}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: shell.cardBorder.withValues(alpha: 0.5)),
    );
    return TextField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 15, color: shell.titleColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: shell.cardBackground,
        hintText: hint,
        hintStyle: TextStyle(color: shell.hintColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.studentPoint, width: 1.6),
        ),
      ),
    );
  }
}
