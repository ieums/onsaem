import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/auth/data/auth_models.dart';

/// 회원가입 — 학생 / 강사 역할 선택
class SignupRoleScreen extends StatelessWidget {
  const SignupRoleScreen({super.key, this.social});

  final SocialSignupArgs? social;

  static const _backgroundColor = Color(0xFFF8F9FD);
  static const _titleColor = Color(0xFF1A1D26);
  static const _subtitleColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _titleColor),
          onPressed: () => context.go(RoutePaths.login),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                          const Text(
                            '회원가입',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _titleColor,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '어떤 역할로 가입하시겠어요?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: _subtitleColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _RoleCard(
                            iconBackgroundColor: AppColors.roleStudentAccent,
                            borderColor: AppColors.roleStudentBorder,
                            leadingIcon: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            title: '학생으로 회원가입하기',
                            description: '질문하고 강사님과 실시간으로 소통해요',
                            onTap: () => context.push(
                              RoutePaths.signupStudent,
                              extra: social == null
                                  ? null
                                  : SocialSignupArgs(
                                      provider: social!.provider,
                                      role: UserRole.student,
                                      token: social!.token,
                                      profile: social!.profile,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RoleCard(
                            iconBackgroundColor: AppColors.primaryBlue,
                            borderColor: AppColors.primaryBlue.withValues(alpha: 0.35),
                            leadingIcon: const _WhiteboardIcon(),
                            title: '강사로 회원가입하기',
                            description: '학생들의 질문에 답하고 수익을 창출해요',
                            onTap: () => context.push(
                              RoutePaths.signupTutor,
                              extra: social == null
                                  ? null
                                  : SocialSignupArgs(
                                      provider: social!.provider,
                                      role: UserRole.tutor,
                                      token: social!.token,
                                      profile: social!.profile,
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
}

/// 사진처럼 칠판/화이트보드 형태 (강사 역할)
class _WhiteboardIcon extends StatelessWidget {
  const _WhiteboardIcon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 16, // 기존 18 → 16
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3), // 패딩 축소
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _boardLine(width: 11),
              const SizedBox(height: 1),
              _boardLine(width: 11),
              const SizedBox(height: 1),
              _boardLine(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _boardLine({required double width}) {
    return Container(
      width: width,
      height: 2.5,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.iconBackgroundColor,
    required this.borderColor,
    required this.leadingIcon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Color iconBackgroundColor;
  final Color borderColor;
  final Widget leadingIcon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: leadingIcon,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D26),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
