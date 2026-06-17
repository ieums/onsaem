import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/auth/screens/login_screen.dart';
import 'package:ieum/features/auth/screens/signup_role_screen.dart';
import 'package:ieum/features/auth/screens/student_signup_screen.dart';
import 'package:ieum/features/auth/screens/tutor_signup_screen.dart';
import 'package:ieum/features/onboarding/screens/onboarding_screen.dart';
import 'package:ieum/features/student/screens/student_shell_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_shell_screen.dart';
import '../features/auth/screens/temp_login_screen.dart';
import '../features/lesson/presentation/lesson_screen.dart';
import '../features/matching/models/searching_problem_model.dart';
import '../features/matching/screens/problem_detail_screen.dart';

final appRouter = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  initialLocation: '/',
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final user = container.read(currentUserProvider);
    final isProtected = state.matchedLocation.startsWith('/tutor') ||
        state.matchedLocation.startsWith('/student');
    if (user == null && isProtected) return '/';
    return null;
  },
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
    GoRoute(
      path: '/',
      builder: (_, _) => const TempLoginScreen(),
    ),
    GoRoute(
      path: '/lesson',
      builder: (_, state) => LessonScreen(
        channelName: state.extra as String,
      ),
    ),
    GoRoute(
      path: '/problem-detail',
      builder: (_, state) => ProblemDetailScreen(
        problem: state.extra as SearchingProblemModel,
      ),
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('페이지를 찾을 수 없습니다: ${state.uri}')),
  ),
);