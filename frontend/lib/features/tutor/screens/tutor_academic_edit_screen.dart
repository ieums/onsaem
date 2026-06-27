import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
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
  bool _loading = true;
  bool _saving = false;

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
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
    return Theme(
      data: theme,
      child: Builder(builder: (context) {
        final shell = ShellTheme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('학력 관리',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
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
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white))
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
