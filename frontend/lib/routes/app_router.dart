import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ieum/core/providers/onboarding_seen_provider.dart';
import 'package:ieum/core/providers/permissions_gate.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/features/onboarding/onboarding_review_args.dart';
import 'package:ieum/features/onboarding/screens/onboarding_permissions_screen.dart';
import 'package:ieum/features/onboarding/screens/student_onboarding_themed_screen.dart';
import 'package:ieum/features/onboarding/screens/tutor_onboarding_themed_screen.dart';
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
import 'package:ieum/features/auth/data/auth_models.dart';

final appRouter = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  // 앱 시작 시 온보딩(스플래시)부터. 3초 후 로그인으로 이동하고,
  // 이미 로그인된 사용자는 로그인 화면 진입 즉시 redirect로 역할별 홈으로 보내진다.
  initialLocation: RoutePaths.onboarding,
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

    // 로그인됨 + 역할 홈으로 가는데 해당 역할 온보딩을 아직 안 봤으면 → 온보딩 1회.
    // (온보딩 경로 '/onboarding/...'는 역할 홈과 다르고 isProtected도 아니라 루프 없음)
    if (user != null) {
      final seen = container.read(onboardingSeenProvider);
      if (loc == RoutePaths.studentHome && !user.isTutor && !seen.student) {
        return RoutePaths.onboardingStudent;
      }
      if (loc == RoutePaths.tutorHome && user.isTutor && !seen.tutor) {
        return RoutePaths.onboardingTutor;
      }
    }
    return null;
  },
  routes: [
    // ─── 유나 라우트 ───────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: RoutePaths.onboardingStudent,
      builder: (context, state) =>
          _buildRoleOnboarding(context, state, isTutor: false),
    ),
    GoRoute(
      path: RoutePaths.onboardingTutor,
      builder: (context, state) =>
          _buildRoleOnboarding(context, state, isTutor: true),
    ),
    GoRoute(
      path: RoutePaths.onboardingPermissions,
      builder: (context, state) {
        final isTutor = state.extra is bool ? state.extra as bool : false;
        return Theme(
          data: AppTheme.light, // 첫 실행이라 라이트 고정
          child: OnboardingPermissionsScreen(
            isTutor: isTutor,
            onDone: () async {
              await markPermissionsPrompted();
              if (context.mounted) {
                context.go(isTutor
                    ? RoutePaths.tutorHome
                    : RoutePaths.studentHome);
              }
            },
          ),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.signup,
      builder: (_, state) => SignupRoleScreen(
        social: state.extra is SocialSignupArgs
            ? state.extra as SocialSignupArgs
            : null,
      ),
    ),
        GoRoute(
      path: RoutePaths.signupStudent,
      builder: (_, state) => StudentSignupScreen(
        isEditMode: state.uri.queryParameters['edit'] == 'true',
        social: state.extra is SocialSignupArgs
            ? state.extra as SocialSignupArgs
            : null,
      ),
    ),
    GoRoute(
      path: RoutePaths.signupTutor,
      builder: (_, state) => TutorSignupScreen(
        isEditMode: state.uri.queryParameters['edit'] == 'true',
        social: state.extra is SocialSignupArgs
            ? state.extra as SocialSignupArgs
            : null,
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

/// 역할별 온보딩(themed) 화면 빌더 — 첫 실행 게이팅과 마이페이지 다시보기를 함께 처리.
///  - extra 없음(첫 실행): 항상 라이트 + 완료/건너뛰기 시 "봤음" 저장 후 역할 홈으로.
///  - extra=[OnboardingReviewArgs](다시보기): 전달된 밝기로 렌더 + 플래그 불변 + pop 복귀.
Widget _buildRoleOnboarding(
  BuildContext context,
  GoRouterState state, {
  required bool isTutor,
}) {
  final args = state.extra is OnboardingReviewArgs
      ? state.extra as OnboardingReviewArgs
      : null;
  final isReview = args != null;
  final brightness = args?.brightness ?? Brightness.light; // 첫 실행은 항상 라이트
  final themeData =
      brightness == Brightness.dark ? AppTheme.shellDark : AppTheme.light;

  void finish() {
    if (isReview) {
      if (context.canPop()) context.pop();
      return;
    }
    // 첫 실행: "봤음" 저장 후, 일괄 권한 화면을 거쳐 홈으로(이미 띄웠거나 web이면 바로 홈).
    markOnboardingSeen(ProviderScope.containerOf(context), isTutor: isTutor);
    _goAfterOnboarding(context, isTutor: isTutor);
  }

  final screen = isTutor
      ? TutorOnboardingThemedScreen(onStart: finish, onSkip: finish)
      : StudentOnboardingThemedScreen(onStart: finish, onSkip: finish);

  return Theme(data: themeData, child: screen);
}

/// 온보딩 완료/건너뛰기 후: 첫 실행 1회만 일괄 권한 화면을 거쳐 역할 홈으로.
///  - web: 권한 화면 스킵(permission_handler 미지원) → 바로 홈.
///  - 이미 권한 안내를 띄웠으면(permissions_prompted) → 바로 홈(거부자는 기능별 게이트가 처리).
Future<void> _goAfterOnboarding(
  BuildContext context, {
  required bool isTutor,
}) async {
  final home = isTutor ? RoutePaths.tutorHome : RoutePaths.studentHome;
  if (kIsWeb) {
    context.go(home);
    return;
  }
  final prompted = await wasPermissionsPrompted();
  if (!context.mounted) return;
  if (prompted) {
    context.go(home);
    return;
  }
  context.go(RoutePaths.onboardingPermissions, extra: isTutor);
}