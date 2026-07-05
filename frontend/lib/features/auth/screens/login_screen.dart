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
import 'dart:math';
import 'package:ieum/features/auth/web/oauth_web_popup.dart';
import 'package:ieum/features/auth/web/pkce.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:google_sign_in_web/web_only.dart' as google_web;
import 'package:ieum/features/auth/data/auth_repository.dart';

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
  // 학생 강조색(연두) — 토글 글씨·입력 포커스 테두리. 진한 녹색 대신 밝은 연두.
  static const _studentAccent = Color(0xFFD2E096);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isTutor = false;   
  bool _isLoading = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _googleAuthSub =
          GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _onGoogleWebSignedIn(event.user);
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _googleAuthSub?.cancel();
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
            selectedColor: _studentAccent, // 학생 = 연두(D2E096)
            onTap: () => setState(() => _isTutor = false),
          ),
          _roleTab(
            label: '강사',
            selected: _isTutor,
            selectedColor: AppColors.primaryBlue, // 강사 = 보라
            onTap: () => setState(() => _isTutor = true),
          ),
        ],
      ),
    );
  }

  Widget _roleTab({
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              color: selected ? selectedColor : _hintColor,
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
      if (kIsWeb) {
        await _kakaoLoginWeb();
        return;
      }
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
      await _handleOAuth(provider: 'kakao', token: token.accessToken);
    } catch (e) {
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '카카오 로그인에 실패했어요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _kakaoLoginWeb() async {
    const jsClientId = '380528dcd96294365cde242f7b47da0b'; 
    final pkce = Pkce.generate();
    final state = _randomState();
    final redirectUri = _redirectUriFor('/kakao_callback.html').toString();

    final authorizeUrl = Uri.https('kauth.kakao.com', '/oauth/authorize', {
      'client_id': jsClientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'code_challenge': pkce.challenge,
      'code_challenge_method': 'S256',
      'state': state,
    }).toString();

    final result =
        await openOAuthPopup(url: authorizeUrl, popupName: 'kakao_login');
    if (result == null || !mounted) return;
    if ((result['error'] ?? '').isNotEmpty) {
      _showMessage('카카오 로그인에 실패했어요.');
      return;
    }
    if (result['state'] != state) {
      _showMessage('카카오 로그인 검증에 실패했어요.');
      return;
    }
    final code = result['code'] ?? '';
    if (code.isEmpty) {
      _showMessage('카카오 로그인에 실패했어요.');
      return;
    }

    final accessToken = await ref.read(authRepositoryProvider).kakaoWebExchange(
          code: code,
          redirectUri: redirectUri,
          codeVerifier: pkce.verifier,
        );
    await _handleOAuth(provider: 'kakao', token: accessToken);
  }
    // ─── 네이버 로그인 ───────────────────────────
    Future<void> _naverLogin() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        await _naverLoginWeb();
        return;
      }
      final result = await FlutterNaverLogin.logIn();
      if (result.status.name != 'loggedIn') {
        if (!mounted) return;
        if (result.status.name == 'error') {
          _showMessage('네이버 로그인에 실패했어요. 잠시 후 다시 시도해주세요.');
        }
        return;
      }
      final naverToken = await FlutterNaverLogin.getCurrentAccessToken();
      await _handleOAuth(provider: 'naver', token: naverToken.accessToken);
    } catch (e) {
      debugPrint('[naver] 로그인 실패: $e');
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '네이버 로그인에 실패했어요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

    Future<void> _naverLoginWeb() async {
    const clientId = 'smQZkJ5_2f4gisBEjCtC'; 
    final state = _randomState();
    final redirectUri = _redirectUriFor('/naver_callback.html').toString();

    final authorizeUrl = Uri.https('nid.naver.com', '/oauth2.0/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'state': state,
    }).toString();

    final result =
        await openOAuthPopup(url: authorizeUrl, popupName: 'naver_login');
    if (result == null || !mounted) return;
    if ((result['error'] ?? '').isNotEmpty) {
      _showMessage('네이버 로그인에 실패했어요.');
      return;
    }
    if (result['state'] != state) {
      _showMessage('네이버 로그인 검증에 실패했어요.');
      return;
    }
    final code = result['code'] ?? '';
    if (code.isEmpty) {
      _showMessage('네이버 로그인에 실패했어요.');
      return;
    }

    final accessToken = await ref
        .read(authRepositoryProvider)
        .naverWebExchange(code: code, state: state);
    await _handleOAuth(provider: 'naver', token: accessToken);
  }

  String _randomState() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
  }
    Uri _redirectUriFor(String path) {
    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
    );
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
      await _handleOAuth(provider: 'google', token: idToken);
    } catch (e) {
      debugPrint('[google] 로그인 실패: $e');
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '구글 로그인에 실패했어요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _onGoogleWebSignedIn(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      _showMessage('구글 로그인에 실패했어요.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _handleOAuth(provider: 'google', token: idToken);
    } catch (e) {
      if (!mounted) return;
      _showMessage(apiErrorMessage(e, fallback: '구글 로그인에 실패했어요.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
    String _homeFor(UserRole role) =>
      role == UserRole.tutor ? RoutePaths.tutorHome : RoutePaths.studentHome;

  /// 소셜 1단계: 기존 회원이면 홈, 신규면 가입 폼으로.
  Future<void> _handleOAuth({
    required String provider,
    required String token,
  }) async {
    final role = _isTutor ? UserRole.tutor : UserRole.student;
    final result = await ref
        .read(authControllerProvider)
        .oauthCheck(provider: provider, token: token);
    if (!mounted) return;
    if (result.registered) {
      context.go(_homeFor(result.tokens!.role)); // 역할은 서버 판정값
    } else {
      // 신규 소셜 사용자 → 역할 선택 화면 경유(토글로 자동 가입 방지)
      context.push(
        RoutePaths.signup,
        extra: SocialSignupArgs(
          provider: provider,
          role: role,
          token: token,
          profile: result.profile!,
        ),
      );
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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
                    // 한 화면에 다 들어가도록 가운데 정렬 + 간격 압축.
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const _BrandTitle(),
                      const SizedBox(height: 22),
                      _buildRoleToggle(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        hint: '이메일',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 20),
                      _buildPrimaryButton(
                        label: _isLoading ? '로그인 중...' : '로그인',
                        onPressed: _isLoading ? null : _login,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LinkText(
                            label: '회원가입',
                            onTap: () => context.push(RoutePaths.signup),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '|',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFC2C6CF),
                              ),
                            ),
                          ),
                          _LinkText(
                            label: '비밀번호를 잊으셨나요?',
                            onTap: () => context.push(
                              RoutePaths.passwordReset,
                              extra: PasswordResetArgs(isTutor: _isTutor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildOrDivider(),
                      const SizedBox(height: 18),
                      _buildSocialCircles(),
                      const SizedBox(height: 12),
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
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          // 학생이면 학생색(연두 D2E096), 강사면 보라
          borderSide: BorderSide(
            color: _isTutor ? AppColors.primaryBlue : _studentAccent,
            width: 1.5,
          ),
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
      height: 48,
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
  Widget _buildGoogleSocialButton() {
    final circle = _SocialCircle(
      onPressed: _isLoading ? () {} : _googleLogin,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFDADCE0),
      iconAsset: 'assets/icons/google_logo.png',
      iconSize: 30,
    );
    if (!kIsWeb) return circle;

    // 웹은 GIS가 authenticate() 직접 호출을 막아서, 진짜 구글 버튼을 투명하게 위에 겹쳐 클릭만 위임.
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          circle,
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: google_web.renderButton(
                configuration: google_web.GSIButtonConfiguration(
                  type: google_web.GSIButtonType.icon,
                  shape: google_web.GSIButtonShape.pill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 소셜 로그인 — 원형 아이콘 버튼 3개를 가로로.
  Widget _buildSocialCircles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGoogleSocialButton(),
        const SizedBox(width: 22),
        _SocialCircle(
          onPressed: _isLoading ? () {} : _kakaoLogin,
          backgroundColor: _kakaoYellow,
          borderColor: _kakaoYellow,
          iconAsset: 'assets/icons/kakao_logo.png',
          iconSize: 30,
        ),
        const SizedBox(width: 22),
        _SocialCircle(
          onPressed: _isLoading ? () {} : _naverLogin,
          backgroundColor: const Color(0xFF03A94D),
          borderColor: const Color(0xFF03A94D),
          iconAsset: 'assets/icons/naver_logo.png',
          iconSize: 30,
        ),
      ],
    );
  }
}

/// 작은 텍스트 링크 (회원가입 / 비밀번호 찾기).
class _LinkText extends StatelessWidget {
  const _LinkText({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B6B6B),
        ),
      ),
    );
  }
}

/// 원형 소셜 로그인 버튼 — 아이콘만.
class _SocialCircle extends StatelessWidget {
  const _SocialCircle({
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconAsset,
    required this.iconSize,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final String iconAsset;
  final double iconSize;

  static const double _size = 58;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(side: BorderSide(color: borderColor, width: 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Center(
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: Image.asset(
                iconAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image_outlined,
                  size: iconSize,
                  color: const Color(0xFF9AA3B2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 사진 상단 로고 자리 — 캐릭터 로고(login_mascot.png) + 텍스트
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 캐릭터 로고 — assets/images/login_mascot.png 에 파일을 넣으면 표시.
        // 아직 없으면 여백 없이 폴백(빌드 안 깨짐).
        Image.asset(
          'assets/images/login_mascot.png',
          height: 176,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 10),
        const Text(
          '온샘',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1D26),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'ONSAEM',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: Color(0xFF1A1D26),
          ),
        ),
      ],
    );
  }
}
