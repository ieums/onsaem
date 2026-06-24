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
const _reasonLabels = {
  'NO_SHOW': '무단 이탈/노쇼',
  'ABUSE': '욕설/비방',
  'INAPPROPRIATE': '불쾌한 콘텐츠',
  'SPAM': '스팸/광고',
  'FRAUD': '사기/허위',
  'OTHER': '기타',
};

/// 내 활동 — 내가 접수한 신고 목록. GET /reports/me
class StudentMyReportsScreen extends ConsumerWidget {
  const StudentMyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
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
                color: AppColors.studentInk,
                onRefresh: () => ref.refresh(myReportsProvider.future),
                child: async.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(color: AppColors.studentInk),
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
