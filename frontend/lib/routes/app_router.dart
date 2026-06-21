import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/features/auth/screens/login_screen.dart';
import 'package:ieum/features/auth/screens/signup_role_screen.dart';
import 'package:ieum/features/auth/screens/student_signup_screen.dart';
import 'package:ieum/features/auth/screens/tutor_signup_screen.dart';
import 'package:ieum/features/onboarding/screens/onboarding_screen.dart';
import 'package:ieum/features/student/screens/student_classroom_screen.dart';
import 'package:ieum/features/student/screens/student_credit_recharge_screen.dart';
import 'package:ieum/features/student/screens/student_matching_wait_screen.dart';
import 'package:ieum/features/student/screens/student_problem_upload_screen.dart';
import 'package:ieum/features/student/screens/student_question_status_screen.dart';
import 'package:ieum/features/student/screens/student_tutor_profile_screen.dart';
import 'package:ieum/features/student/screens/student_tutor_selection_screen.dart';
import 'package:ieum/features/student/screens/student_report_screen.dart';
import 'package:ieum/features/student/screens/student_review_write_screen.dart';
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
      path: RoutePaths.studentProblemUpload,
      builder: (_, _) => const StudentProblemUploadScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentMatchingWait,
      builder: (_, _) => const StudentMatchingWaitScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentTutorSelection,
      builder: (_, _) => const StudentTutorSelectionScreen(),
    ),
    GoRoute(
      path: '${RoutePaths.studentTutorProfile}/:tutorId',
      builder: (_, state) => StudentTutorProfileScreen(
        tutorId: state.pathParameters['tutorId']!,
      ),
    ),
    GoRoute(
      path: RoutePaths.studentQuestionStatus,
      builder: (_, _) => const StudentQuestionStatusScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentClassroom,
      builder: (_, _) => const StudentClassroomScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentReviewWrite,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is! StudentReviewWriteArgs) {
          return const Scaffold(
            body: Center(child: Text('리뷰 정보를 불러올 수 없습니다.')),
          );
        }
        return StudentReviewWriteScreen(args: extra);
      },
    ),
    GoRoute(
      path: RoutePaths.studentReport,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is! StudentReportArgs) {
          return const Scaffold(
            body: Center(child: Text('신고 정보를 불러올 수 없습니다.')),
          );
        }
        return StudentReportScreen(args: extra);
      },
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
