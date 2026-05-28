import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/features/auth/screens/login_screen.dart';
import 'package:ieum/features/auth/screens/signup_role_screen.dart';
import 'package:ieum/features/auth/screens/student_signup_screen.dart';
import 'package:ieum/features/auth/screens/tutor_signup_screen.dart';
import 'package:ieum/features/onboarding/screens/onboarding_screen.dart';
import 'package:ieum/features/student/screens/student_shell_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_shell_screen.dart';
import '../core/theme/app_colors.dart';
import '../features/lesson/presentation/lesson_screen.dart';

final appRouter = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  initialLocation: RoutePaths.onboarding,
  routes: [
    // ─── 유나 라우트 ───────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.signup,
      builder: (_, _) => const SignupRoleScreen(),
    ),
    GoRoute(
      path: RoutePaths.signupStudent,
      builder: (_, _) => const StudentSignupScreen(),
    ),
    GoRoute(
      path: RoutePaths.signupTutor,
      builder: (_, state) => TutorSignupScreen(
        isEditMode: state.uri.queryParameters['edit'] == 'true',
      ),
    ),
    GoRoute(
      path: RoutePaths.studentHome,
      builder: (_, _) => const StudentShellScreen(),
    ),
    GoRoute(
      path: RoutePaths.tutorHome,
      builder: (_, _) => const TutorShellScreen(),
    ),

    // ─── 화상강의 라우트 ───────────────────────────────────────────────────
    // TODO: 매칭 시스템 연동 후 EntryScreen 및 '/' 라우트 제거 예정
    GoRoute(
      path: '/',
      builder: (context, state) => const EntryScreen(),
    ),
    GoRoute(
      path: '/lesson',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>;
        return LessonScreen(
          channelName: params['channelName'] as String,
          uid: params['uid'] as int,
          isTutor: params['isTutor'] as bool,
        );
      },
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('페이지를 찾을 수 없습니다: ${state.uri}')),
  ),
);

// ─── 테스트용 입장 화면 (매칭 시스템 연동 후 제거 예정) ──────────────────────────

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _channelCtrl = TextEditingController();
  final _uidCtrl = TextEditingController(text: '1');
  bool _isTutor = true;

  @override
  void dispose() {
    _channelCtrl.dispose();
    _uidCtrl.dispose();
    super.dispose();
  }

  void _enter() {
    if (!_formKey.currentState!.validate()) return;
    final uid = int.tryParse(_uidCtrl.text.trim());
    if (uid == null) return;
    context.go('/lesson', extra: {
      'channelName': _channelCtrl.text.trim(),
      'uid': uid,
      'isTutor': _isTutor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('온샘'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '수업 입장',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _channelCtrl,
                  decoration: const InputDecoration(
                    labelText: '채널명',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '채널명을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _uidCtrl,
                  decoration: const InputDecoration(
                    labelText: 'UID (숫자)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || int.tryParse(v.trim()) == null)
                          ? '숫자를 입력해주세요'
                          : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('역할:',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('튜터(강사)')),
                        ButtonSegment(value: false, label: Text('학생')),
                      ],
                      selected: {_isTutor},
                      onSelectionChanged: (s) =>
                          setState(() => _isTutor = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _enter,
                  child: const Text('수업 입장',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}