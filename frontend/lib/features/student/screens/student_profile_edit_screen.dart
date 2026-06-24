import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
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
      _phone.text = (me['phone'] as String?) ?? '';
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 16, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: '생년월일 선택',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.studentInk),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
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
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
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
                    child: CircularProgressIndicator(color: AppColors.studentInk),
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
                            keyboard: TextInputType.phone),
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
                              foregroundColor: AppColors.studentInk,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4, color: Colors.white),
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
                    color: AppColors.studentInk, strokeWidth: 2.6)
                : (resolved == null
                    ? const Icon(Icons.person,
                        size: 52, color: AppColors.studentInk)
                    : null),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.studentInk,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploadingImage ? null : _pickAndUploadImage,
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 16, color: Colors.white),
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
      {TextInputType? keyboard}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: shell.cardBorder.withValues(alpha: 0.5)),
    );
    return TextField(
      controller: c,
      keyboardType: keyboard,
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
          borderSide: const BorderSide(color: AppColors.studentInk, width: 1.6),
        ),
      ),
    );
  }
}
