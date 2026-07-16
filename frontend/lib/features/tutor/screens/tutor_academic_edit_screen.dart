import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/api_error.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/tutor/widgets/tutor_action_button_style.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/mypage_provider.dart';

class TutorAcademicEditScreen extends ConsumerStatefulWidget {
  const TutorAcademicEditScreen({super.key});

  @override
  ConsumerState<TutorAcademicEditScreen> createState() =>
      _TutorAcademicEditScreenState();
}

class _TutorAcademicEditScreenState
    extends ConsumerState<TutorAcademicEditScreen> {
  final _school = TextEditingController();
  final _major = TextEditingController();
  final _experience = TextEditingController();
  String? _educationStatus;
  String? _verificationStatus;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingDoc = false;

  static const _educationOptions = [
    ('ENROLLED', '재학'),
    ('ON_LEAVE', '휴학'),
    ('GRADUATED', '졸업'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await ref.read(mypageRepositoryProvider).getMe();
      _school.text = (me['school'] as String?) ?? '';
      _major.text = (me['major'] as String?) ?? '';
      final exp = me['experienceYears'];
      if (exp != null) _experience.text = '$exp';
      _educationStatus = me['educationStatus'] as String?;
      _verificationStatus = me['verificationStatus'] as String?;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _school.dispose();
    _major.dispose();
    _experience.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(mypageRepositoryProvider).updateProfile(
            school: _school.text.trim().isNotEmpty
                ? _school.text.trim()
                : null,
            major: _major.text.trim().isNotEmpty
                ? _major.text.trim()
                : null,
            educationStatus: _educationStatus,
            experienceYears:
                int.tryParse(_experience.text.trim()),
          );
      if (!mounted) return;
      ref.invalidate(meProvider);
      _snack('학력 정보가 수정됐어요.');
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('수정에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> _reuploadDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (file.name.isEmpty || bytes == null || bytes.isEmpty) {
        _snack('파일을 읽지 못했어요.');
        return;
      }
      setState(() => _uploadingDoc = true);
      await ref
          .read(mypageRepositoryProvider)
          .reuploadVerificationDocument(bytes, filename: file.name);
      if (!mounted) return;
      ref.invalidate(meProvider);
      setState(() {
        _uploadingDoc = false;
        _verificationStatus = 'PENDING';
      });
      _snack('증빙 서류를 제출했어요. 관리자 승인을 기다려 주세요.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingDoc = false);
      _snack(apiErrorMessage(e, fallback: '제출에 실패했어요. (PDF·JPG·PNG)'));
    }
  }

  ({String label, Color color}) _verificationChip(String? s) => switch (s) {
        'VERIFIED' => (label: '인증 완료', color: AppColors.incomeGreen),
        'REJECTED' => (label: '반려됨', color: AppColors.logoutRed),
        'PENDING' => (label: '심사 중', color: const Color(0xFFE8A33D)),
        _ => (label: '미제출', color: const Color(0xFF6B7280)),
      };

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m)));
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
            title: const Text('학력 관리',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 20)),
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
                      _label(shell, '학교'),
                      _field(shell, _school, '학교명'),
                      const SizedBox(height: 20),
                      _label(shell, '학과'),
                      _field(shell, _major, '학과명'),
                      const SizedBox(height: 20),
                      _label(shell, '재학 상태'),
                      const SizedBox(height: 8),
                      _buildEducationSelector(shell),
                      const SizedBox(height: 20),
                      _label(shell, '경력 연수'),
                      _field(shell, _experience, '예: 3',
                          keyboard: TextInputType.number),
                      const SizedBox(height: 24),
                      _label(shell, '학력 증빙 서류'),
                      const SizedBox(height: 8),
                      _buildVerificationSection(shell, isDark),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _saving ? null : _save,
                          style: tutorOutlinedButtonStyle(isDark, radius: 14),
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

  Widget _buildVerificationSection(ShellTheme shell, bool isDark) {
    final v = _verificationChip(_verificationStatus);
    final String desc = _verificationStatus == 'REJECTED'
        ? '반려됐어요. 새 서류를 제출해 주세요.'
        : _verificationStatus == 'VERIFIED'
            ? '인증이 완료된 서류예요. 변경하려면 재제출하세요.'
            : '관리자 승인 후 강의를 신청할 수 있어요.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: shell.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: shell.cardBorder.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: v.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(v.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: v.color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(desc,
                    style: TextStyle(
                        fontSize: 12.5, color: shell.hintColor, height: 1.4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _uploadingDoc ? null : _reuploadDocument,
            style: tutorOutlinedButtonStyle(isDark, radius: 12),
            icon: _uploadingDoc
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: AppColors.primaryBlue))
                : const Icon(Icons.upload_file_rounded, size: 19),
            label: Text(_uploadingDoc ? '제출 중…' : '증빙 서류 재제출',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationSelector(ShellTheme shell) {
    return Wrap(
      spacing: 8,
      children: _educationOptions.map((opt) {
        final (code, label) = opt;
        final selected = _educationStatus == code;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) =>
              setState(() => _educationStatus = code),
          selectedColor:
              AppColors.primaryBlue.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: selected
                ? AppColors.primaryBlue
                : shell.subtitleColor,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
          side: BorderSide(
            color: selected
                ? AppColors.primaryBlue
                : shell.cardBorder,
          ),
        );
      }).toList(),
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

  Widget _field(
    ShellTheme shell,
    TextEditingController c,
    String hint, {
    TextInputType? keyboard,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          BorderSide(color: shell.cardBorder.withValues(alpha: 0.5)),
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
