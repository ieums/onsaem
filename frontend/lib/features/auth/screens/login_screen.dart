import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/auth/data/auth_controller.dart';
import 'package:ieum/features/auth/screens/password_reset_screen.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:ieum/features/auth/data/auth_models.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ieum/core/network/api_error.dart';

class LoginScreen extends ConsumerStatefulWidget {      
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();   
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _backgroundColor = Color(0xFFF8F9FD);
  static const _inputFillColor = Color(0xFFEEF1F7);
  static const _hintColor = Color(0xFF9AA3B2);

  static const _kakaoYellow = Color(0xFFFEE500);
  static const _kakaoBrown = Color(0xFF3C1E1E);

  /// 소셜 버튼 아이콘 — Google/Kakao 동일 크기
  static const double _socialIconSize = 24;
  static const double _socialIconGap = 8;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isTutor = false;   
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
    // ─── 학생/강사 토글 UI ───────────────────────
  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _inputFillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _roleTab(
            label: '학생',
            selected: !_isTutor,
            onTap: () => setState(() => _isTutor = false),
          ),
          _roleTab(
            label: '강사',
            selected: _isTutor,
            onTap: () => setState(() => _isTutor = true),
          ),
        ],
      ),
    );
  }

  Widget _roleTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primaryBlue : _hintColor,
            ),
          ),
        ),
      ),
    );
  }

  // ─── 로그인 실행 ─────────────────────────────
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authControllerProvider);
      if (_isTutor) {
        await auth.tutorLogin(email: email, password: password);
      } else {
        await auth.studentLogin(email: email, password: password);
      }
      if (!mounted) return;
      context.go(_isTutor ? RoutePaths.tutorHome : RoutePaths.studentHome);
      } catch (e) {
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '로그인에 실패했어요. 이메일·비밀번호를 확인해주세요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
    // ─── 카카오 로그인 ───────────────────────────
  Future<void> _kakaoLogin() async {
    setState(() => _isLoading = true);
    try {
      OAuthToken? token;
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            return;
          }
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      await ref.read(authControllerProvider).oauthLogin(
            provider: 'kakao',
            role: _isTutor ? UserRole.tutor : UserRole.student,
            token: token.accessToken,
          );
      if (!mounted) return;
      context.go(_isTutor ? RoutePaths.tutorHome : RoutePaths.studentHome);
    } catch (e) {
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '카카오 로그인에 실패했어요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
    // ─── 네이버 로그인 ───────────────────────────
  Future<void> _naverLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status.name != 'loggedIn') {
        return;
      }
      final naverToken = await FlutterNaverLogin.getCurrentAccessToken();

      await ref.read(authControllerProvider).oauthLogin(
            provider: 'naver',
            role: _isTutor ? UserRole.tutor : UserRole.student,
            token: naverToken.accessToken,
          );
      if (!mounted) return;
      context.go(_isTutor ? RoutePaths.tutorHome : RoutePaths.studentHome);
    } catch (e) {
      debugPrint('[naver] 로그인 실패: $e');
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '네이버 로그인에 실패했어요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
    // ─── 구글 로그인 ───────────────────────────
  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        if (!mounted) return;
        _showMessage('구글 로그인에 실패했어요.');
        return;
      }
      await ref.read(authControllerProvider).oauthLogin(
            provider: 'google',
            role: _isTutor ? UserRole.tutor : UserRole.student,
            token: idToken,
          );
      if (!mounted) return;
      context.go(_isTutor ? RoutePaths.tutorHome : RoutePaths.studentHome);
    } catch (e) {
      debugPrint('[google] 로그인 실패: $e');
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '구글 로그인에 실패했어요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _testLessonLogin() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authControllerProvider);
      if (_isTutor) {
        await auth.tutorLogin(email: 'tutor@test.com', password: 'test1234');
      } else {
        await auth.studentLogin(email: 'student@test.com', password: 'test1234');
      }
      if (!mounted) return;
      context.go('/lesson', extra: {'channelName': 'test-channel-3', 'imageUrls': <String>[]});
    } catch (e) {
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '테스트 로그인에 실패했어요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandTitle(),
                      const SizedBox(height: 48),
                      _buildRoleToggle(),              
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailController,
                        hint: '이메일',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _passwordController,
                        hint: '비밀번호',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _hintColor,
                            size: 22,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildPrimaryButton(
                        label: _isLoading ? '로그인 중...' : '로그인',
                        onPressed: _isLoading ? null : _login,
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push(
                            RoutePaths.passwordReset,
                            extra: PasswordResetArgs(isTutor: _isTutor),
                          ),
                          child: const Text(
                            '비밀번호를 잊으셨나요?',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B6B6B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildOrDivider(),
                      const SizedBox(height: 28),
                      _buildGoogleLoginButton(onPressed: _isLoading ? () {} : _googleLogin,),
                      const SizedBox(height: 12),
                      _buildKakaoLoginButton(onPressed: _isLoading ? () {} : _kakaoLogin,),
                      const SizedBox(height: 12),
                      _buildNaverLoginButton(
                        onPressed: _isLoading ? () {} : _naverLogin,),
                      const SizedBox(height: 28),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push(RoutePaths.signup),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D26),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _testLessonLogin,
                          child: const Text(
                            '화상강의 테스트',
                            style: TextStyle(
                              fontSize: 12,
                              color: _hintColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1A1D26)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 16),
        filled: true,
        fillColor: _inputFillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1D26),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '또는',
            style: TextStyle(fontSize: 14, color: _hintColor),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
      ],
    );
  }

  Widget _buildGoogleLoginButton({required VoidCallback onPressed}) {
    return _SocialLoginButton(
      onPressed: onPressed,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFDADCE0),
      label: 'Google 계정으로 로그인',
      labelColor: const Color(0xFF1A1D26),
      iconAsset: 'assets/icons/google_logo.png',
      iconSize: 28,
      iconPadding: const EdgeInsets.only(left: 5),
    );
  }

  Widget _buildKakaoLoginButton({required VoidCallback onPressed}) {
    return _SocialLoginButton(
      onPressed: onPressed,
      backgroundColor: _kakaoYellow,
      borderColor: _kakaoYellow,
      label: 'Kakao 계정으로 로그인',
      labelColor: _kakaoBrown,
      iconAsset: 'assets/icons/kakao_logo.png',
    );
  }
}
  Widget _buildNaverLoginButton({required VoidCallback onPressed}) {
    return _SocialLoginButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF03A94D),
      borderColor: const Color(0xFF03A94D),
      label: 'Naver 계정으로 로그인',
      labelColor: Colors.white,
      iconAsset: 'assets/icons/naver_logo.png',
    );
  }

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.label,
    required this.labelColor,
    required this.iconAsset,
    this.iconSize,
    this.iconPadding,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final String label;
  final Color labelColor;
  final String iconAsset;
  final double? iconSize;
  final EdgeInsetsGeometry? iconPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: iconPadding ?? EdgeInsets.zero,
                child: SizedBox(
                  width: iconSize ?? _LoginScreenState._socialIconSize,
                  height: iconSize ?? _LoginScreenState._socialIconSize,
                  child: Image.asset(
                    iconAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.broken_image_outlined,
                      size: iconSize ?? _LoginScreenState._socialIconSize,
                      color: const Color(0xFF9AA3B2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _LoginScreenState._socialIconGap),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 사진 상단 로고 자리 — 텍스트만 (캐릭터 로고 제외)
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '온샘',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1D26),
            height: 1.1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'ONSAEM',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: Color(0xFF1A1D26),
          ),
        ),
      ],
    );
  }
}
