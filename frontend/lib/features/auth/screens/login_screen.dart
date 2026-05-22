import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _backgroundColor = Color(0xFFF8F9FD);
  static const _inputFillColor = Color(0xFFEEF1F7);
  static const _hintColor = Color(0xFF9AA3B2);

  static const _kakaoYellow = Color(0xFFFEE500);
  static const _kakaoBrown = Color(0xFF3C1E1E);

  /// 소셜 버튼 아이콘 — Google/Kakao 동일 크기
  static const double _socialIconSize = 24;
  static const double _socialIconGap = 8;

  bool _obscurePassword = true;

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
                      _buildTextField(
                        hint: '이메일',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
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
                        label: '로그인',
                        onPressed: () {
                          context.go(RoutePaths.studentHome);
                        },
                      ),
                      const SizedBox(height: 28),
                      _buildOrDivider(),
                      const SizedBox(height: 28),
                      _buildGoogleLoginButton(onPressed: () {}),
                      const SizedBox(height: 12),
                      _buildKakaoLoginButton(onPressed: () {}),
                      const SizedBox(height: 28),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push(RoutePaths.signup),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
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
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
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
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
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
            color: AppColors.primaryBlue,
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
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }
}
