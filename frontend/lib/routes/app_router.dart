import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/features/auth/screens/login_screen.dart';
import 'package:ieum/features/auth/screens/signup_role_screen.dart';
import 'package:ieum/features/auth/screens/student_signup_screen.dart';
import 'package:ieum/features/auth/screens/tutor_signup_screen.dart';
import 'package:ieum/features/onboarding/screens/onboarding_screen.dart';
import 'package:ieum/features/student/screens/student_credit_recharge_screen.dart';
import 'package:ieum/features/student/screens/student_shell_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_shell_screen.dart';

final appRouter = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  initialLocation: RoutePaths.onboarding,
  routes: [
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
      builder: (_, state) => StudentSignupScreen(
        isEditMode: state.uri.queryParameters['edit'] == 'true',
      ),
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
      path: RoutePaths.studentCreditRecharge,
      builder: (_, _) => const StudentCreditRechargeScreen(),
    ),
    GoRoute(
      path: RoutePaths.tutorHome,
      builder: (_, _) => const TutorShellScreen(),
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('페이지를 찾을 수 없습니다: ${state.uri}')),
  ),
);
