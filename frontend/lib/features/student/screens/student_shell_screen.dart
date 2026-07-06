import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/permissions/lesson_permission_dialog.dart';
import 'package:ieum/core/permissions/media_permissions.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/storage/welcome_bonus_flag.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/app_shell_tab_bar.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/providers/student_applicant_watcher.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/routes/app_router.dart';
import 'package:ieum/features/student/providers/student_shell_tab_provider.dart';
import 'package:ieum/features/student/screens/student_home_screen.dart';
import 'package:ieum/features/student/screens/student_lessons_screen.dart';
import 'package:ieum/features/student/screens/student_my_page_screen.dart';
import 'package:ieum/features/student/screens/student_ai_tutor_list_screen.dart';

/// 학생 탭: 홈 · 복습 · AI튜터 · 마이페이지
class StudentShellScreen extends ConsumerStatefulWidget {
  const StudentShellScreen({super.key});

  @override
  ConsumerState<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends ConsumerState<StudentShellScreen> {
  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
    (
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories,
      label: '복습',
    ),
    (
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy,
      label: 'AI튜터',
    ),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이페이지'),
  ];

  static final _screens = [
    StudentHomeScreen(),
    StudentLessonsScreen(),
    StudentAiTutorListScreen(),
    StudentMyPageScreen(),
  ];

  // 매칭 요청 다이얼로그가 열려 있는 동안의 컨텍스트.
  // 상대(강사)가 취소/거절하거나 타임아웃되면 이걸로 다이얼로그를 강제로 닫는다.
  BuildContext? _matchDialogContext;

  @override
  void initState() {
    super.initState();
    // 권한 자동 요청은 하지 않는다(온보딩 일괄 화면/마이페이지 토글에서만). 초기화만.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppNotificationService.instance.initialize();
      // 가입 직후 1회: 환영 보너스 안내 다이얼로그.
      if (await consumePendingWelcomeBonus() && mounted) {
        _showWelcomeBonusDialog();
      }
    });
  }

  /// 가입 축하 보너스 안내 — 가입 직후 홈 진입 시 1회만(로컬 플래그로 소비됨).
  void _showWelcomeBonusDialog() {
    // 색은 다이얼로그 컨텍스트(ShellTheme.of)가 아니라 학생 shell 테마에서 직접 뽑는다.
    // (안 그러면 루트 보라 시드 테마가 잡혀 배경이 연보라로 뜬다)
    final isDark = ref.read(shellDarkModeProvider);
    final scheme =
        (isDark ? AppTheme.shellDark : AppTheme.shellLight).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: scheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                Text('가입을 환영해요!',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface)),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: '가입 축하 '),
                    TextSpan(
                        text: '50코인',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.studentPoint)),
                    const TextSpan(
                        text: '을 선물로 드렸어요.\nAI 튜터에게 바로 질문해보세요!'),
                  ]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, height: 1.5, color: scheme.secondary),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('나중에',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref
                              .read(studentShellTabIndexProvider.notifier)
                              .state = studentShellAiTutorTabIndex;
                        },
                        style: accentDialogButtonStyle(
                          accent: AppColors.studentPoint,
                          isDark: isDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('AI튜터 써보기',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StudentMatchingSession?>(studentMatchingSessionProvider,
        (prev, next) {
      if (!mounted) return;
      final prevTutorId = prev?.matchRequestedTutorId;
      final nextTutorId = next?.matchRequestedTutorId;
      if (nextTutorId != null && nextTutorId != prevTutorId) {
        _showMatchRequestedDialog(context, ref, nextTutorId);
      }
      // 상대(강사)가 취소/거절했거나 타임아웃되면 요청이 사라진다 → 열려있는 다이얼로그 닫기.
      if (prevTutorId != null && nextTutorId == null) {
        _dismissMatchDialog();
        // 수락/거절·취소로 요청이 끝났으니 홈 복구 배너도 갱신(사라지게).
        ref.invalidate(pendingConfirmProvider);
      }

      final prevMsg = prev?.matchCancelledMessage;
      final nextMsg = next?.matchCancelledMessage;
      if (nextMsg != null && nextMsg != prevMsg) {
        _showMatchCancelledDialog(context, ref, nextMsg);
      }

      final wasExpiring = prev?.isSearchExpiringSoon ?? false;
      final isExpiring = next?.isSearchExpiringSoon ?? false;
      if (isExpiring && !wasExpiring) {
        _showExtendDialog(context, ref);
      }

      final prevStatus = prev?.status;
      final nextStatus = next?.status;
      if (nextStatus == StudentMatchingSessionStatus.connected &&
          prevStatus != StudentMatchingSessionStatus.connected) {
        final session = next!;
        if (session.channelName != null) {
          appRouter.go('/lesson', extra: {
            'channelName': session.channelName!,
            'imageUrls': session.imageUrls,
            'subject': session.subject,
            'tutorProfileImageUrl': session.tutorProfileImageUrl,
            'studentProfileImageUrl': session.studentProfileImageUrl,
          });
        }
      }
    });

    // 로그인 동안 '지원 강사 수' 실시간 워처를 살려둔다(모든 대기 문제 대상).
    ref.watch(studentApplicantWatcherProvider);

    final tabIndex = ref.watch(studentShellTabIndexProvider);
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      // 탭 선택색 등은 primary를 따름 → 학생 강조색(studentPoint)로 통일.
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor: isDark
          ? AppColors.shellScaffoldDark
          : AppColors.studentScaffoldLight,
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: IndexedStack(index: tabIndex, children: _screens),
        bottomNavigationBar: AppShellTabBar(
          selectedIndex: tabIndex,
          onDestinationSelected: (i) =>
              ref.read(studentShellTabIndexProvider.notifier).state = i,
          tabs: _tabs,
        ),
      ),
    );
  }

  Future<void> _showMatchRequestedDialog(
      BuildContext context, WidgetRef ref, int tutorId) async {
    // 매칭 요청 다이얼로그는 항상 하나만 유지한다. 이미 떠 있으면 먼저 닫아,
    // 낡은 다이얼로그가 밑에 쌓여 엉뚱한 강사에게 수락/거절이 나가는 걸 막는다.
    _dismissMatchDialog();
    final isDark = ref.read(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme:
          baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
    );

    BuildContext? myDialogContext;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        myDialogContext = dialogContext;
        _matchDialogContext = dialogContext;
        // 색은 다이얼로그 컨텍스트(ShellTheme.of)가 아니라 로컬 shell 테마에서 직접 뽑는다.
        // 그러지 않으면 루트(보라 시드) 테마가 잡혀 배경이 연보라로 뜨고 다크모드도 안 먹는다.
        final scheme = theme.colorScheme;
        return Theme(
          data: theme,
          // 뒤로가기로 닫혀 매칭 요청을 놓치지 않도록 막는다(수락/거절만 가능).
          // 강사 취소/타임아웃 시엔 _dismissMatchDialog가 Navigator.pop으로 직접 닫는다.
          child: PopScope(
            canPop: false,
            child: AlertDialog(
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            title: Text(
              '매칭 요청',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            content: Text(
              '선택하신 강사님과 연결됐어요.\n지금 바로 수업을 시작할까요?',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: scheme.secondary,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.studentPoint),
                child: const Text('거절',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: accentDialogButtonStyle(
                  accent: AppColors.studentPoint,
                  isDark: isDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                ),
                child: const Text('수락',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
            ),
          ),
        );
      },
    );

    // 그 사이 더 새로운 다이얼로그가 떴다면 그 컨텍스트를 덮어쓰지 않도록,
    // 내가 띄운 다이얼로그가 여전히 '현재'일 때만 정리한다(겹침 경합 방지).
    if (identical(_matchDialogContext, myDialogContext)) {
      _matchDialogContext = null;
    }
    if (!mounted) return;
    // confirmed == null → 상대 취소로 자동 닫힘. 이미 취소됐으므로 추가 호출 없음.
    if (confirmed == null) return;
    if (confirmed) {
      // 입장 직전 카메라·마이크 게이트(시스템 팝업 없이 상태만 확인).
      // 미허용이면 매칭을 취소하고 설정 유도 → 강의실 진입 자체를 막아 오류방 방지.
      // (권한 없으면 수업이 불가하므로 깔끔히 거절 처리, 학생은 처음부터 다시 매칭)
      final allowed = await MediaPermissions.ensureForLessonEntry();
      if (!mounted) return;
      if (!allowed) {
        await ref
            .read(studentMatchingSessionProvider.notifier)
            .cancelConfirm(tutorId);
        if (!context.mounted) return;
        await showLessonPermissionDialog(context, ref);
        return;
      }
      try {
        await ref
            .read(studentMatchingSessionProvider.notifier)
            .confirmMatch(tutorId);
      } on DioException catch (e) {
        if (!context.mounted) return;
        // 낡은/만료된 매칭을 확정하려다 400 등이 나면 크래시 대신 안내 후 상태 정리.
        final msg = e.response?.statusCode == 400
            ? '이미 만료되었거나 처리된 매칭이에요. 강사를 다시 선택해 주세요.'
            : '연결에 실패했어요. 잠시 후 다시 시도해 주세요.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        ref.invalidate(pendingConfirmProvider);
      }
    } else {
      await ref
          .read(studentMatchingSessionProvider.notifier)
          .cancelConfirm(tutorId);
    }
  }

  /// 상대 취소/타임아웃 시 열려있는 매칭 요청 다이얼로그를 결과 없이 닫는다(confirmed=null).
  void _dismissMatchDialog() {
    final ctx = _matchDialogContext;
    _matchDialogContext = null; // 먼저 비워 재진입 방지
    if (!mounted || ctx == null || !ctx.mounted) return;
    final nav = Navigator.of(ctx);
    // 다이얼로그가 실제로 떠 있을 때만 닫는다. canPop=false면 마지막 페이지라 pop하면 크래시.
    if (nav.canPop()) nav.pop();
  }

  // build는 본문을 shell 테마로 감싸지만 아래 다이얼로그들은 State.context(그 위=루트 보라 테마)에서
  // 열려 배경이 연보라로 잡힌다 → 공용 다이얼로그에 shell 테마를 명시적으로 넘긴다.
  ThemeData get _dialogTheme =>
      ref.read(shellDarkModeProvider) ? AppTheme.shellDark : AppTheme.shellLight;

  /// 매칭 취소 안내 다이얼로그(강사 화면과 동일 디자인).
  Future<void> _showMatchCancelledDialog(
      BuildContext context, WidgetRef ref, String message) async {
    await showConfirmDialog(
      context: context,
      title: '매칭 취소',
      message: message,
      cancelText: null,
      confirmText: '확인',
      theme: _dialogTheme,
    );
    ref
        .read(studentMatchingSessionProvider.notifier)
        .clearMatchCancelledMessage();
  }

  Future<void> _showExtendDialog(BuildContext context, WidgetRef ref) async {
    final extended = await showConfirmDialog(
      context: context,
      title: '탐색 종료 임박',
      message: '강사 탐색 시간이 거의 다 됐어요.\n하루 더 연장하시겠습니까?',
      cancelText: '탐색 취소',
      confirmText: '하루 연장',
      barrierDismissible: false,
      theme: _dialogTheme,
    );

    if (!mounted) return;
    if (extended) {
      await ref.read(studentMatchingSessionProvider.notifier).extendSearch();
    } else {
      await ref.read(studentMatchingSessionProvider.notifier).cancelMatching();
    }
  }
}
