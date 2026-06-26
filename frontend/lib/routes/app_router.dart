import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/auth/screens/login_screen.dart';
import 'package:ieum/features/auth/screens/signup_role_screen.dart';
import 'package:ieum/features/auth/screens/student_signup_screen.dart';
import 'package:ieum/features/auth/screens/tutor_signup_screen.dart';
import 'package:ieum/features/auth/screens/password_reset_screen.dart';
import 'package:ieum/features/onboarding/screens/onboarding_screen.dart';
import 'package:ieum/features/student/screens/student_credit_recharge_screen.dart';
import 'package:ieum/features/student/screens/student_subscription_screen.dart';
import 'package:ieum/features/student/screens/student_my_reviews_screen.dart';
import 'package:ieum/features/student/screens/student_my_reports_screen.dart';
import 'package:ieum/features/student/screens/student_profile_edit_screen.dart';
import 'package:ieum/features/student/screens/student_problem_upload_screen.dart';
import 'package:ieum/features/student/screens/student_problem_list_screen.dart';
import 'package:ieum/features/student/screens/student_tutor_profile_screen.dart';
import 'package:ieum/features/student/screens/student_tutor_selection_screen.dart';
import 'package:ieum/features/student/screens/student_report_screen.dart';
import 'package:ieum/features/student/screens/student_review_write_screen.dart';
import 'package:ieum/features/student/screens/student_shell_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_shell_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_profile_edit_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_academic_edit_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_my_reviews_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_my_reports_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_lesson_complete_screen.dart';
import '../features/lesson/presentation/lesson_screen.dart';
import '../features/matching/models/searching_problem_model.dart';
import '../features/matching/screens/problem_detail_screen.dart';

final appRouter = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  initialLocation: '/login',
    redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final user = container.read(currentUserProvider);
    final loc = state.matchedLocation;
    final isProtected = loc.startsWith('/tutor') || loc.startsWith('/student');
    final isEntry = loc == '/' || loc == RoutePaths.login;

    // 로그인 상태인데 시작/로그인 화면이면 → 역할별 홈으로
    if (user != null && isEntry) {
      return user.isTutor ? RoutePaths.tutorHome : RoutePaths.studentHome;
    }
    // 미로그인인데 보호 화면이면 → 시작(/)으로
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
      path: RoutePaths.passwordReset,
      builder: (_, state) {
        final args =
            state.extra is PasswordResetArgs ? state.extra as PasswordResetArgs : null;
        return PasswordResetScreen(
          initialEmail: args?.email,
          isTutor: args?.isTutor ?? false,
        );
      },
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
      path: RoutePaths.studentSubscription,
      builder: (_, _) => const StudentSubscriptionScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentMyReviews,
      builder: (_, _) => const StudentMyReviewsScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentMyReports,
      builder: (_, _) => const StudentMyReportsScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentProfileEdit,
      builder: (_, _) => const StudentProfileEditScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentProblemUpload,
      builder: (_, _) => const StudentProblemUploadScreen(),
    ),
    GoRoute(
      path: RoutePaths.studentProblemList,
      builder: (_, _) => const StudentProblemListScreen(),
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
      path: RoutePaths.tutorLessonComplete,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is! TutorLessonCompleteArgs) {
          return const Scaffold(
            body: Center(child: Text('강의 정보를 불러올 수 없습니다.')),
          );
        }
        return TutorLessonCompleteScreen(args: extra);
      },
    ),
    GoRoute(
      path: RoutePaths.tutorHome,
      builder: (_, _) => const TutorShellScreen(),
    ),
    GoRoute(
      path: RoutePaths.tutorProfileEdit,
      builder: (_, _) => const TutorProfileEditScreen(),
    ),
    GoRoute(
      path: RoutePaths.tutorAcademicEdit,
      builder: (_, _) => const TutorAcademicEditScreen(),
    ),
    GoRoute(
      path: RoutePaths.tutorMyReviews,
      builder: (_, _) => const TutorMyReviewsScreen(),
    ),
    GoRoute(
      path: RoutePaths.tutorMyReports,
      builder: (_, _) => const TutorMyReportsScreen(),
    ),

    // ─── 화상강의 라우트 ───────────────────────────────────────────────────
    GoRoute(
      path: '/lesson',
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          return LessonScreen(
            channelName: extra['channelName'] as String,
            imageUrls: (extra['imageUrls'] as List?)?.cast<String>() ?? const [],
            subject: extra['subject'] as String?,
            tutorProfileImageUrl: extra['tutorProfileImageUrl'] as String?,
            studentProfileImageUrl: extra['studentProfileImageUrl'] as String?,
          );
        }
        return LessonScreen(channelName: extra as String);
      },
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