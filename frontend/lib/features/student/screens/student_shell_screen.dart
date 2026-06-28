import 'package:flutter/material.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/widgets/app_shell_tab_bar.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNotificationService.instance.initialize().then((_) {
        AppNotificationService.instance.ensurePermission();
      });
    });
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

    final tabIndex = ref.watch(studentShellTabIndexProvider);
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
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
    final isDark = ref.read(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme:
          baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _matchDialogContext = dialogContext;
        final shell = ShellTheme.of(dialogContext);
        return Theme(
          data: theme,
          child: AlertDialog(
            backgroundColor: shell.cardBackground,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            title: Text(
              '매칭 요청',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: shell.titleColor,
              ),
            ),
            content: Text(
              '선택하신 강사님과 연결됐어요.\n지금 바로 수업을 시작할까요?',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: shell.subtitleColor,
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
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.studentPoint,
                    foregroundColor:
                        isDark ? AppColors.shellOnSurfaceLight : Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 11)),
                child: const Text('수락',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );

    _matchDialogContext = null;
    if (!mounted) return;
    // confirmed == null → 상대 취소로 자동 닫힘. 이미 취소됐으므로 추가 호출 없음.
    if (confirmed == null) return;
    if (confirmed) {
      await ref
          .read(studentMatchingSessionProvider.notifier)
          .confirmMatch(tutorId);
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

  /// 매칭 취소 안내 다이얼로그(강사 화면과 동일 디자인).
  Future<void> _showMatchCancelledDialog(
      BuildContext context, WidgetRef ref, String message) async {
    await showConfirmDialog(
      context: context,
      title: '매칭 취소',
      message: message,
      cancelText: null,
      confirmText: '확인',
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
    );

    if (!mounted) return;
    if (extended) {
      await ref.read(studentMatchingSessionProvider.notifier).extendSearch();
    } else {
      await ref.read(studentMatchingSessionProvider.notifier).cancelMatching();
    }
  }
}
