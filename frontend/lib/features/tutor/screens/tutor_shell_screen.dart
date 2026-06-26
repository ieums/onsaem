import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/app_shell_tab_bar.dart';
import 'package:ieum/features/matching/providers/matching_provider.dart'
    show MatchingState, matchingProvider, tutorApplicationsProvider;
import 'package:ieum/features/tutor/screens/tutor_home_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_my_page_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_request_list_screen.dart';
import 'package:ieum/features/tutor/screens/tutor_settlement_screen.dart';

/// 강사 탭: 홈 · 신청리스트 · 정산 · 마이페이지
class TutorShellScreen extends ConsumerStatefulWidget {
  const TutorShellScreen({super.key});

  @override
  ConsumerState<TutorShellScreen> createState() => _TutorShellScreenState();
}

class _TutorShellScreenState extends ConsumerState<TutorShellScreen> {
  int _index = 0;

  // 매칭 요청 다이얼로그가 열려 있는 동안의 컨텍스트.
  // 상대(학생)가 취소하거나 타임아웃되면 이걸로 다이얼로그를 강제로 닫는다.
  BuildContext? _matchDialogContext;

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
    (icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt, label: '신청리스트'),
    (
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: '정산',
    ),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이페이지'),
  ];

  static final _screens = [
    TutorHomeScreen(),
    TutorRequestListScreen(),
    TutorSettlementScreen(),
    TutorMyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);

    ref.listen<MatchingState>(matchingProvider, (prev, next) {
      if (!mounted) return;
      final prevReq = prev?.matchRequestedProblemId;
      final nextReq = next.matchRequestedProblemId;
      if (nextReq != null && nextReq != prevReq) {
        _showMatchRequestedDialog(
          context,
          nextReq,
          next.matchRequestedMessage ?? '',
        );
      }
      // 상대(학생)가 취소했거나 타임아웃되면 요청이 사라진다 → 열려있는 다이얼로그 닫기.
      if (prevReq != null && nextReq == null) {
        _dismissMatchDialog();
      }
      if (next.matchCancelledMessage != null &&
          next.matchCancelledMessage != prev?.matchCancelledMessage) {
        _showMatchCancelledDialog(context, next.matchCancelledMessage!);
      }
    });

    return Theme(
      data: isDark ? AppTheme.shellDark : AppTheme.shellLight,
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: AppShellTabBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          tabs: _tabs,
        ),
      ),
    );
  }

  Future<void> _showMatchRequestedDialog(
      BuildContext context, int problemId, String message) async {
    final isDark = ref.read(shellDarkModeProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _matchDialogContext = dialogContext;
        return AlertDialog(
          title:
              const Text('매칭 요청', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(
            message.isNotEmpty
                ? message
                : '학생과 연결됐어요.\n지금 바로 수업을 시작할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('거절'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor:
                    isDark ? AppColors.shellOnSurfaceLight : Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('수락',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    _matchDialogContext = null;
    if (!mounted) return;
    // confirmed == null → 상대 취소로 자동 닫힘. 이미 취소됐으므로 추가 호출 없음.
    if (confirmed == null) return;
    if (confirmed) {
      await ref.read(matchingProvider.notifier).confirmMatch(problemId);
    } else {
      await ref.read(matchingProvider.notifier).cancelConfirm(problemId);
    }
    if (!mounted) return;
    ref.read(tutorApplicationsProvider.notifier).refresh();
    ref.read(matchingProvider.notifier).refresh();
  }

  /// 상대 취소/타임아웃 시 열려있는 매칭 요청 다이얼로그를 결과 없이 닫는다(confirmed=null).
  void _dismissMatchDialog() {
    final ctx = _matchDialogContext;
    if (ctx != null && ctx.mounted) {
      Navigator.of(ctx).pop();
    }
    _matchDialogContext = null;
  }

  void _showMatchCancelledDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('매칭 취소',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(message),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(matchingProvider.notifier).clearMatchCancelled();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
