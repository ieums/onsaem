import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/widgets/app_shell_tab_bar.dart';
import 'package:ieum/features/matching/providers/matching_provider.dart'
    show MatchingState, matchingProvider, tutorApplicationsProvider;
import 'package:ieum/features/tutor/screens/tutor_home_screen.dart';
import 'package:ieum/core/notifications/notification_center.dart';
import 'package:ieum/features/tutor/providers/tutor_notification_provider.dart';
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
  void initState() {
    super.initState();
    // 인앱 알람(배너)용 초기화 — 오프라인 토글과 무관하게 STOMP로 도착하면 알림이 뜨도록.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNotificationService.instance.initialize().then((_) {
        AppNotificationService.instance.ensurePermission();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);

    ref.listen<MatchingState>(matchingProvider, (prev, next) {
      if (!mounted) return;
      final prevReq = prev?.matchRequestedProblemId;
      final nextReq = next.matchRequestedProblemId;
      if (nextReq != null && nextReq != prevReq) {
        // 인앱 알람: 신청해둔 문제를 학생이 선택했음 (오프라인이어도 도착하면 뜸).
        AppNotificationService.instance.showBanner(
          dedupeKey: 'match-requested-$nextReq',
          title: '학생이 선택했어요!',
          body: '신청한 문제를 학생이 선택했어요. 5분 안에 수락해 주세요.',
        );
        ref.read(tutorNotificationInboxProvider.notifier).add(
              dedupeKey: 'match-requested-$nextReq',
              title: '학생이 선택했어요',
              body: '신청한 문제를 학생이 선택했어요. 5분 안에 수락해 주세요.',
              kind: NotificationKind.matching,
            );
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
        ref.read(tutorNotificationInboxProvider.notifier).add(
              dedupeKey:
                  'match-cancelled-${DateTime.now().millisecondsSinceEpoch}',
              title: '매칭이 취소됐어요',
              body: next.matchCancelledMessage!,
              kind: NotificationKind.matching,
            );
        _showMatchCancelledDialog(context, next.matchCancelledMessage!);
      }
    });

    return Theme(
      // 라이트모드 홈 배경에 보라빛 톤. 다크는 공통.
      data: isDark
          ? AppTheme.shellDark
          : AppTheme.shellLight.copyWith(
              scaffoldBackgroundColor: AppColors.tutorScaffoldLight),
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
        final shell = ShellTheme.of(dialogContext);
        return AlertDialog(
          backgroundColor: shell.cardBackground,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            '매칭 요청',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: shell.titleColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.isNotEmpty
                    ? message
                    : '학생과 연결됐어요.\n지금 바로 수업을 시작할까요?',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: shell.subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
              // 5분 카운트다운 — 0이 되면 자동으로 닫힘(서버 CONFIRMING 타임아웃과 동일).
              _MatchCountdown(
                duration: const Duration(minutes: 5),
                onExpire: () {
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.pop(dialogContext);
                  }
                },
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
              child: const Text('거절',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor:
                    isDark ? AppColors.shellOnSurfaceLight : Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
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
    _matchDialogContext = null; // 먼저 비워 재진입 방지
    if (!mounted || ctx == null || !ctx.mounted) return;
    final nav = Navigator.of(ctx);
    // 다이얼로그가 실제로 떠 있을 때만 닫는다. canPop=false면 마지막 페이지라 pop하면 크래시.
    if (nav.canPop()) nav.pop();
  }

  Future<void> _showMatchCancelledDialog(
      BuildContext context, String message) async {
    final ok = await showConfirmDialog(
      context: context,
      title: '매칭 취소',
      message: message,
      cancelText: null,
      confirmText: '확인',
      isTutor: true,
    );
    // 원본과 동일하게 '확인'을 눌렀을 때만 상태를 비운다(바깥 탭으로 닫으면 유지).
    if (ok && mounted) {
      ref.read(matchingProvider.notifier).clearMatchCancelled();
    }
  }
}

/// 매칭 요청 다이얼로그용 5분 카운트다운. 0이 되면 onExpire 호출.
class _MatchCountdown extends StatefulWidget {
  const _MatchCountdown({required this.duration, this.onExpire});

  final Duration duration;
  final VoidCallback? onExpire;

  @override
  State<_MatchCountdown> createState() => _MatchCountdownState();
}

class _MatchCountdownState extends State<_MatchCountdown> {
  late int _remaining = widget.duration.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        widget.onExpire?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _remaining.clamp(0, 359999);
    final m = s ~/ 60;
    final sec = s % 60;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 16, color: AppColors.primaryBlue),
        const SizedBox(width: 6),
        Text(
          '남은 시간 $m:${sec.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }
}
