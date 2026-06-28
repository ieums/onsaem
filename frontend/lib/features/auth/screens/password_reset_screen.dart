import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/auth/data/auth_repository.dart';
import 'package:ieum/features/auth/utils/password_rules.dart';

/// 비밀번호 재설정 화면 라우트 인자 — 진입점(로그인/마이페이지)에서 전달.
class PasswordResetArgs {
  const PasswordResetArgs({this.email, this.isTutor = false});
  final String? email; // 프리필할 이메일
  final bool isTutor; // 색상 테마(학생/강사) 구분
}

/// 비밀번호 재설정 — 이메일 인증 코드 방식 (LOCAL 계정 전용).
/// 1단계: 이메일 입력 → 코드 발송. 2단계: 코드 + 새 비밀번호 입력 → 변경.
/// [initialEmail]이 주어지면(마이페이지의 로그인 유저) 이메일을 프리필한다.
/// [isTutor]에 따라 강조색(학생=studentInk / 강사=primaryBlue)을 다르게 적용.
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key, this.initialEmail, this.isTutor = false});

  final String? initialEmail;
  final bool isTutor;

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  Color get _accent =>
      widget.isTutor ? AppColors.primaryBlue : AppColors.studentPoint;

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 1; // 1: 이메일, 2: 코드+새 비번
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) _email.text = widget.initialEmail!;
    // 비밀번호 입력에 따라 규칙 체크리스트를 실시간 갱신
    _password.addListener(_onTyping);
    _confirm.addListener(_onTyping);
  }

  void _onTyping() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _snack('올바른 이메일을 입력해 주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 2;
      });
      _snack('인증 코드를 보냈어요. 이메일을 확인해 주세요.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('코드 발송에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> _resetPassword() async {
    final code = _code.text.trim();
    final pw = _password.text;
    if (code.length != 6) {
      _snack('6자리 인증 코드를 입력해 주세요.');
      return;
    }
    if (!passwordSatisfiesAll(pw)) {
      _snack('비밀번호 조건을 모두 충족해 주세요.');
      return;
    }
    if (pw != _confirm.text) {
      _snack('비밀번호가 일치하지 않아요.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            email: _email.text.trim(),
            code: code,
            newPassword: pw,
          );
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('비밀번호가 변경됐어요. 새 비밀번호로 로그인해 주세요.');
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('인증 코드가 올바르지 않거나 만료됐어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: _accent),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
    return Theme(
      data: theme,
      child: Builder(builder: (context) {
        final shell = ShellTheme.of(context);
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            foregroundColor: shell.titleColor,
            title: Text('비밀번호 재설정',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: shell.titleColor)),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Text(
                  _step == 1
                      ? '가입한 이메일로 인증 코드를 보내드려요.'
                      : '메일로 받은 6자리 코드와 새 비밀번호를 입력해 주세요.',
                  style: TextStyle(
                      fontSize: 14, color: shell.subtitleColor, height: 1.45),
                ),
                const SizedBox(height: 4),
                Text(
                  '소셜(카카오·구글) 계정은 비밀번호가 없어 재설정 대상이 아니에요.',
                  style: TextStyle(fontSize: 12, color: shell.hintColor),
                ),
                const SizedBox(height: 24),
                _label(shell, '이메일'),
                _field(
                  shell,
                  _email,
                  'you@example.com',
                  keyboard: TextInputType.emailAddress,
                  enabled: _step == 1 && widget.initialEmail == null,
                ),
                if (_step == 2) ...[
                  const SizedBox(height: 20),
                  _label(shell, '인증 코드 (6자리)'),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          shell,
                          _code,
                          '000000',
                          keyboard: TextInputType.number,
                          maxLength: 6,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _busy ? null : _sendCode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accent,
                            side: BorderSide(color: _accent),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('재전송',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label(shell, '새 비밀번호'),
                  _field(shell, _password, '새 비밀번호',
                      obscure: _obscure, toggleObscure: true),
                  const SizedBox(height: 10),
                  PasswordRulesChecklist(
                    password: _password.text,
                    accent: _accent,
                    compact: true,
                  ),
                  const SizedBox(height: 20),
                  _label(shell, '새 비밀번호 확인'),
                  _field(shell, _confirm, '새 비밀번호 확인', obscure: _obscure),
              if (_confirm.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _confirm.text == _password.text
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 16,
                      color: _confirm.text == _password.text
                          ? const Color(0xFF2E9E6B)
                          : AppColors.error,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _confirm.text == _password.text
                          ? '비밀번호가 일치해요'
                          : '비밀번호가 일치하지 않아요',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _confirm.text == _password.text
                            ? const Color(0xFF2E9E6B)
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _busy ? null : (_step == 1 ? _sendCode : _resetPassword),
                // 통일 스타일: 테두리만 역할 특징색 + 흰/다크 배경 + 검정/특징색 글씨.
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.shellSurfaceDark : Colors.white,
                  foregroundColor: isDark ? _accent : Colors.black,
                  side: BorderSide(color: _accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _busy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: _accent),
                      )
                    : Text(_step == 1 ? '인증 코드 받기' : '비밀번호 변경',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
                ],
              ),
            ),
          );
        }),
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
    bool obscure = false,
    bool toggleObscure = false,
    bool enabled = true,
    int? maxLength,
    List<TextInputFormatter>? formatters,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: shell.cardBorder.withValues(alpha: 0.6)),
    );
    return TextField(
      controller: c,
      keyboardType: keyboard,
      obscureText: obscure,
      enabled: enabled,
      maxLength: maxLength,
      inputFormatters: formatters,
      style: TextStyle(fontSize: 15, color: shell.titleColor),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: enabled
            ? shell.cardBackground
            : shell.cardBackground.withValues(alpha: 0.5),
        hintText: hint,
        hintStyle: TextStyle(color: shell.hintColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent, width: 1.6),
        ),
        suffixIcon: toggleObscure
            ? IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: shell.hintColor),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
