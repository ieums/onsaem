import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/app_shell_tab_bar.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/routes/app_router.dart';
import 'package:ieum/features/student/providers/student_shell_tab_provider.dart';
import 'package:ieum/features/student/screens/student_home_screen.dart';
import 'package:ieum/features/student/screens/student_lessons_screen.dart';
import 'package:ieum/features/student/screens/student_my_page_screen.dart';
import 'package:ieum/features/student/screens/student_questions_screen.dart';

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
    StudentQuestionsScreen(),
    StudentMyPageScreen(),
  ];

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

      final prevMsg = prev?.matchCancelledMessage;
      final nextMsg = next?.matchCancelledMessage;
      if (nextMsg != null && nextMsg != prevMsg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nextMsg)),
        );
        ref
            .read(studentMatchingSessionProvider.notifier)
            .clearMatchCancelledMessage();
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
          });
        }
      }
    });

    final tabIndex = ref.watch(studentShellTabIndexProvider);
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
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
      builder: (dialogContext) => Theme(
        data: theme,
        child: AlertDialog(
          title: const Text('매칭 요청', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('강사님이 매칭을 요청했습니다. 수업을 시작하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('거절'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.studentPoint,
                  foregroundColor: isDark ? AppColors.shellOnSurfaceLight : Colors.white),
              child: const Text('수락', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      await ref
          .read(studentMatchingSessionProvider.notifier)
          .confirmMatch(tutorId);
    } else {
      await ref
          .read(studentMatchingSessionProvider.notifier)
          .cancelConfirm(tutorId);
    }
  }

  Future<void> _showExtendDialog(BuildContext context, WidgetRef ref) async {
    final isDark = ref.read(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme:
          baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
    );

    final extended = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Theme(
        data: theme,
        child: AlertDialog(
          title: const Text('탐색 종료 임박', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('강사 탐색 시간이 거의 다 됐어요. 30분 연장하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('탐색 취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.studentPoint,
                  foregroundColor: isDark ? AppColors.shellOnSurfaceLight : Colors.white),
              child: const Text('30분 연장', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (extended == true) {
      await ref.read(studentMatchingSessionProvider.notifier).extendSearch();
    } else {
      await ref.read(studentMatchingSessionProvider.notifier).cancelMatching();
    }
  }
}
