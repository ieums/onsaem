import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/mypage_models.dart';
import 'package:ieum/features/student/providers/mypage_provider.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';

const _targetLabels = {
  'TUTOR': '강사',
  'STUDENT': '학생',
  'LESSON': '강의',
  'REVIEW': '리뷰',
};
const _statusLabels = {
  'PENDING': '접수됨',
  'REVIEWING': '검토 중',
  'RESOLVED': '처리 완료',
  'REJECTED': '반려',
};
// 백엔드 ReportReason enum과 동일하게 유지 (코드→표시 라벨).
const _reasonLabels = {
  // 사람(강사/학생)
  'ABUSE': '욕설/모욕',
  'NO_SHOW': '노쇼/불참',
  'INAPPROPRIATE': '부적절한 행동',
  'FRAUD': '사기/허위',
  'SPAM': '스팸/광고',
  // 강의
  'CONNECTION_ISSUE': '연결/음성·영상 문제',
  'TECHNICAL_ISSUE': '기술 오류(녹화·판서 등)',
  'LESSON_NOT_HELD': '강의 미진행/중단',
  // 공통
  'ETC': '기타',
};

/// 내 활동 — 내가 접수한 신고 목록. GET /reports/me
class StudentMyReportsScreen extends ConsumerWidget {
  const StudentMyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.studentScaffoldLight,
    );
    final async = ref.watch(myReportsProvider);

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '내 신고 내역',
              onBack: () => Navigator.of(context).pop(),
            ),
            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.studentPoint,
                onRefresh: () => ref.refresh(myReportsProvider.future),
                child: async.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(color: AppColors.studentPoint),
                    ),
                  ),
                  error: (_, _) => _hint(shell, '신고 내역을 불러오지 못했어요.'),
                  data: (items) {
                    if (items.isEmpty) {
                      return _hint(shell, '접수한 신고가 없어요.');
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _card(shell, items[i]),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hint(ShellTheme shell, String text) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.flag_outlined,
              size: 52, color: shell.hintColor.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: shell.hintColor)),
        ],
      );

  Widget _card(ShellTheme shell, MyReport r) {
    final target = _targetLabels[r.targetType] ?? (r.targetType ?? '대상');
    final statusColor = switch (r.status) {
      'PENDING' => const Color(0xFFE8A33D),
      'RESOLVED' => const Color(0xFF2E9E6B),
      'REJECTED' => AppColors.logoutRed,
      _ => const Color(0xFF6B7280),
    };
    final reasonText =
        r.reasons.map((x) => _reasonLabels[x] ?? x).join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$target 신고',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: shell.titleColor)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusLabels[r.status] ?? (r.status ?? '-'),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),
          if (reasonText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(reasonText,
                style: TextStyle(fontSize: 13, color: shell.subtitleColor)),
          ],
          if ((r.description?.trim().isNotEmpty) ?? false) ...[
            const SizedBox(height: 6),
            Text(r.description!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: shell.hintColor)),
          ],
          if ((r.adminReply?.trim().isNotEmpty) ?? false) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.studentPoint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.studentPoint.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.support_agent_rounded,
                        size: 15, color: shell.titleColor),
                    const SizedBox(width: 5),
                    Text('관리자 답변',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: shell.titleColor)),
                  ]),
                  const SizedBox(height: 6),
                  Text(r.adminReply!.trim(),
                      style: TextStyle(
                          fontSize: 13, height: 1.45, color: shell.titleColor)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(_ymd(r.createdAt),
              style: TextStyle(fontSize: 12, color: shell.hintColor)),
        ],
      ),
    );
  }

  static String _ymd(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}.${two(l.month)}.${two(l.day)}';
  }
}
