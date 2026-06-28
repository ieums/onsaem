// ⚠️ 임시 디자인 비교용 화면 — 다이얼로그 디자인을 한 곳에서 보기 위함.
// 떼어낼 때 이 파일 하나만 삭제하면 됩니다(main.dart 등 다른 파일 변경 없음).
//
// 실행(크롬, 로그인 없이 바로 뜸, 무거운 초기화 없음):
//   flutter run -t lib/dev/dialog_gallery_screen.dart -d chrome
//
// 각 다이얼로그는 실제 화면 코드의 모양을 그대로 재현합니다(콜백/실제 동작은 생략).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/notification_center.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';

void main() {
  runApp(const ProviderScope(child: _DialogGalleryApp()));
}

class _DialogGalleryApp extends StatelessWidget {
  const _DialogGalleryApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dialog Gallery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const DialogGalleryScreen(),
    );
  }
}

class DialogGalleryScreen extends ConsumerWidget {
  const DialogGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;

    // 실제 shell 화면처럼 본문 전체를 shell 테마로 감싼다.
    // Builder로 한 단계 내려가야 아래 context가 이 테마를 물려받아,
    // showDialog가 라이트/다크 테마를 그대로 잡는다.
    return Theme(
      data: baseTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('다이얼로그 갤러리 (임시)'),
              actions: [
                IconButton(
                  tooltip: isDark ? '라이트 모드' : '다크 모드',
                  onPressed: () => ref
                      .read(shellDarkModeProvider.notifier)
                      .update((v) => !v),
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  '버튼을 누르면 현재 앱에 흩어진 다이얼로그가 지금 모양 그대로 뜹니다. '
                  '우측 상단 토글로 라이트/다크를 비교하세요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle(
                    context, '★ 새 표준 confirm 헬퍼 — 버튼 2개 (showConfirmDialog)'),
                _entry(
                  context,
                  label: '1. 질문 삭제 (위험 / 학생)',
                  source: 'danger · student · 취소/삭제',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '질문 삭제',
                    message: '이 질문을 삭제할까요?\n삭제하면 되돌릴 수 없어요.',
                    cancelText: '취소',
                    confirmText: '삭제',
                    isDanger: true,
                  ),
                ),
                _entry(
                  context,
                  label: '2. 질문 삭제 — 상태화면 (위험 / 학생)',
                  source: "danger · student · 취소/삭제 (라벨 '닫기'→'취소' 통일)",
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '질문 삭제',
                    message: '이 질문을 삭제할까요?\n삭제하면 되돌릴 수 없어요.',
                    cancelText: '취소',
                    confirmText: '삭제',
                    isDanger: true,
                  ),
                ),
                _entry(
                  context,
                  label: '3. AI 튜터 종료 (위험 / 학생)',
                  source: 'danger · student · 취소/종료',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '대화 종료',
                    message: '이 AI 튜터 대화를 종료할까요?\n종료하면 더 이상 질문할 수 없어요.',
                    cancelText: '취소',
                    confirmText: '종료',
                    isDanger: true,
                  ),
                ),
                _entry(
                  context,
                  label: '4. 구독 해지 (위험 / 학생)',
                  source: 'danger · student · 취소/해지',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '구독 해지',
                    message: '정말 구독을 해지할까요?\n해지하면 AI 튜터 이용이 바로 중단돼요.',
                    cancelText: '취소',
                    confirmText: '해지',
                    isDanger: true,
                  ),
                ),
                _entry(
                  context,
                  label: '5. 온라인 전환 (일반 / 강사)',
                  source: 'normal · tutor · 닫기/온라인으로 전환',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '오프라인 상태예요',
                    message:
                        '온라인으로 전환해야 학생이 선택할 수 있어요.\n지금 온라인으로 전환할까요?',
                    cancelText: '닫기',
                    confirmText: '온라인으로 전환',
                    isTutor: true,
                  ),
                ),
                _entry(
                  context,
                  label: '6. 출금 — 테두리(A)',
                  source: 'outline · 회색 테두리 · 값=연보라',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '일괄 출금 요청',
                    message: '총 3건의 정산을 일괄 출금 요청합니다.',
                    cancelText: '취소',
                    confirmText: '출금 요청',
                    isTutor: true,
                    highlightLabel: '출금 합계',
                    highlightValue: '240,000원',
                    highlightStyle: ConfirmHighlightStyle.outline,
                  ),
                ),
                _entry(
                  context,
                  label: '6. 출금 — 틴트배경(B)',
                  source: 'tintNeutral · 회색 배경 · 값=연보라',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '일괄 출금 요청',
                    message: '총 3건의 정산을 일괄 출금 요청합니다.',
                    cancelText: '취소',
                    confirmText: '출금 요청',
                    isTutor: true,
                    highlightLabel: '출금 합계',
                    highlightValue: '240,000원',
                    highlightStyle: ConfirmHighlightStyle.tintNeutral,
                  ),
                ),
                _entry(
                  context,
                  label: '6. 출금 — 원본',
                  source: 'tutor_settlement_screen.dart:1618 원본 그대로',
                  onTap: () => _showWithdrawOriginal(context),
                ),
                _entry(
                  context,
                  label: '7. 수업 완료 (위험 / 강사)',
                  source: 'danger · tutor · 취소/완료',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '수업 완료',
                    message: '수업을 종료하시겠습니까?\n녹화가 저장됩니다.',
                    cancelText: '취소',
                    confirmText: '완료',
                    isDanger: true,
                    isTutor: true,
                  ),
                ),
                _entry(
                  context,
                  label: '8. 충전 환불 (위험 / 학생)',
                  source: 'danger · student · 취소/환불',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '충전 환불',
                    message: '10,000원 결제를 환불할까요?\n충전됐던 코인이 회수돼요.',
                    cancelText: '취소',
                    confirmText: '환불',
                    isDanger: true,
                  ),
                ),
                _entry(
                  context,
                  label: '9. 코인 부족 안내 (일반 / 학생)',
                  source: 'normal · student · 닫기/충전하기',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '코인이 부족해요',
                    message: '계속하려면 코인을 충전해야 해요.\n지금 충전할까요?',
                    cancelText: '닫기',
                    confirmText: '충전하기',
                  ),
                ),
                _entry(
                  context,
                  label: '14. 강사 탐색 연장 (일반 / 학생)',
                  source: 'normal · student · 탐색 취소/하루 연장',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '탐색 종료 임박',
                    message: '강사 탐색 시간이 거의 다 됐어요.\n하루 더 연장하시겠습니까?',
                    cancelText: '탐색 취소',
                    confirmText: '하루 연장',
                  ),
                ),
                const SizedBox(height: 8),
                _sectionTitle(
                    context, '★ 새 표준 confirm 헬퍼 — 단일 버튼 (cancelText: null)'),
                _entry(
                  context,
                  label: '12. 매칭 취소 안내 — 강사 (일반 / 강사)',
                  source: 'single · tutor · 확인  ※메시지는 서버값(샘플)',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '매칭 취소',
                    message: '상대방의 사정으로 매칭이 취소되었어요.',
                    cancelText: null,
                    confirmText: '확인',
                    isTutor: true,
                  ),
                ),
                _entry(
                  context,
                  label: '13. 매칭 취소 안내 — 학생 (일반 / 학생)',
                  source: 'single · student · 확인  ※메시지는 서버값(샘플)',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '매칭 취소',
                    message: '상대방의 사정으로 매칭이 취소되었어요.',
                    cancelText: null,
                    confirmText: '확인',
                  ),
                ),
                _entry(
                  context,
                  label: '15. 서버 연결 상태 (일반 / 기본)',
                  source: 'single · 기본역할 · 닫기',
                  onTap: () => showConfirmDialog(
                    context: context,
                    title: '서버 연결 성공',
                    message: '서버 연결 상태: 정상',
                    cancelText: null,
                    confirmText: '닫기',
                  ),
                ),
                const SizedBox(height: 8),
                _sectionTitle(context, '기존 다이얼로그 (현황)'),
                _entry(
                  context,
                  label: '삭제확인 — 문제 목록',
                  source: 'student_problem_list_screen.dart:112',
                  onTap: () => _showProblemListDelete(context),
                ),
                _entry(
                  context,
                  label: '삭제확인 — 문제 상태',
                  source: 'student_problem_status_screen.dart:100',
                  onTap: () => _showProblemStatusDelete(context),
                ),
                _entry(
                  context,
                  label: 'AI 튜터 종료',
                  source: 'student_ai_tutor_screen.dart:83',
                  onTap: () => _showAiTutorClose(context),
                ),
                _entry(
                  context,
                  label: '구독 해지',
                  source: 'student_subscription_screen.dart:79',
                  onTap: () => _showSubscriptionCancel(context),
                ),
                _entry(
                  context,
                  label: '온라인 전환',
                  source: 'problem_detail_screen.dart:52',
                  onTap: () => _showOnlineConversion(context),
                ),
                _entry(
                  context,
                  label: '매칭 요청 — 강사 (B안 스타일 + 카운트다운)',
                  source: 'tutor_shell_screen.dart:124 · 로직 그대로, 스타일만 표준화',
                  onTap: () => _showTutorMatchRequest(context),
                ),
                _entry(
                  context,
                  label: '매칭 요청 — 학생 (B안 스타일)',
                  source: 'student_shell_screen.dart:129 · 로직 그대로, 스타일만 표준화',
                  onTap: () => _showStudentMatchRequest(context),
                ),
                _entry(
                  context,
                  label: '알림센터 (표준 후보)',
                  source: 'notification_center.dart',
                  onTap: () => _showNotificationCenter(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _entry(
    BuildContext context, {
    required String label,
    required String source,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: onTap, child: const Text('열기')),
        ],
      ),
    );
  }

  // ── 1. 삭제확인 — 문제 목록 (student_problem_list_screen.dart:112) ──
  void _showProblemListDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('질문 삭제'),
        content: const Text('이 질문을 삭제할까요? 삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제',
                style: TextStyle(
                    color: AppColors.logoutRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── 2. 삭제확인 — 문제 상태 (student_problem_status_screen.dart:100) ──
  void _showProblemStatusDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('질문 삭제'),
        content: const Text('이 질문을 삭제할까요? 삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(
                    color: AppColors.buttonDanger,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── 3. AI 튜터 종료 (student_ai_tutor_screen.dart:83) ──
  void _showAiTutorClose(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('대화 종료'),
        content: const Text('이 AI 튜터 대화를 종료할까요?\n종료하면 더 이상 질문할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  // ── 4. 구독 해지 (student_subscription_screen.dart:79) ──
  void _showSubscriptionCancel(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('구독 해지'),
        content: const Text('정말 구독을 해지할까요? 해지하면 AI 튜터 이용이 바로 중단돼요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('해지')),
        ],
      ),
    );
  }

  // ── 5. 온라인 전환 (problem_detail_screen.dart:52) ──
  void _showOnlineConversion(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오프라인 상태예요',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            '온라인으로 전환해야 학생이 선택할 수 있어요.\n지금 온라인으로 전환할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('온라인으로 전환',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 6(원본). 일괄 출금 요청 — 금액 강조 박스 포함 (tutor_settlement_screen.dart:1618) ──
  // 샘플 값: 출금 가능 3건 / 합계 240,000원.
  void _showWithdrawOriginal(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '일괄 출금 요청',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '총 3건의 정산을\n일괄 출금 요청합니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '출금 합계',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '240,000원',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('출금 요청'),
          ),
        ],
      ),
    );
  }

  // ── 6. 매칭 요청 — 강사 (tutor_shell_screen.dart:132) ──
  void _showTutorMatchRequest(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shell = ShellTheme.of(context);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                '학생과 연결됐어요.\n지금 바로 수업을 시작할까요?',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: shell.subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
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
  }

  // ── 7. 매칭 요청 — 학생 (student_shell_screen.dart:137) ──
  void _showStudentMatchRequest(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shell = ShellTheme.of(context);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme:
          baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
    );
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
  }

  // ── 8. 알림센터 (notification_center.dart — 표준 후보) ──
  void _showNotificationCenter(BuildContext context) {
    final now = DateTime.now();
    final items = <NotificationViewData>[
      NotificationViewData(
        id: '1',
        title: '새 매칭 요청이 도착했어요',
        body: '학생이 수업을 신청했어요. 지금 확인해 보세요.',
        createdAt: now.subtract(const Duration(minutes: 3)),
        isRead: false,
        kind: NotificationKind.matching,
      ),
      NotificationViewData(
        id: '2',
        title: '수업 연장 안내',
        body: '진행 중인 수업 시간이 10분 남았어요.',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
        kind: NotificationKind.lesson,
      ),
      NotificationViewData(
        id: '3',
        title: '정산이 완료됐어요',
        body: '5월 정산금이 등록하신 계좌로 입금되었습니다.',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
        kind: NotificationKind.settlement,
      ),
      NotificationViewData(
        id: '4',
        title: 'AI 튜터 답변이 준비됐어요',
        body: '질문하신 문제의 풀이가 도착했어요.',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        kind: NotificationKind.aiTutor,
      ),
      NotificationViewData(
        id: '5',
        title: '신고가 접수되었습니다',
        body: '제출하신 신고 내용을 검토하고 있어요.',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
        kind: NotificationKind.report,
      ),
    ];
    showNotificationCenterDialog(
      context,
      items: items,
      onMarkAllRead: () {},
      onRemoveAt: (_) {},
    );
  }
}

/// tutor_shell_screen.dart 의 _MatchCountdown 재현(매칭 요청 다이얼로그의 카운트다운).
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
        const Icon(Icons.timer_outlined,
            size: 16, color: AppColors.primaryBlue),
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
