import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';
import 'package:ieum/features/student/data/tutor_profile_repository.dart';
import 'package:ieum/features/student/models/tutor_profile_detail.dart';
import 'package:ieum/features/student/repositories/mypage_repository.dart';
import 'package:ieum/features/tutor/widgets/review_summary.dart';

class TutorMyReviewsScreen extends ConsumerWidget {
  const TutorMyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final theme =
        (isDark ? AppTheme.shellDark : AppTheme.shellLight).copyWith(
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.tutorScaffoldLight,
    );
    final tutorId = ref.watch(currentUserProvider)?.id;

    return Theme(
      data: theme,
      child: Builder(builder: (context) {
        final shell = ShellTheme.of(context);
        if (tutorId == null) {
          return Scaffold(
            appBar: _appBar(),
            body: Center(
              child: Text('로그인이 필요합니다.',
                  style: TextStyle(color: shell.hintColor)),
            ),
          );
        }
        final async = ref.watch(tutorProfileProvider(tutorId));
        return Scaffold(
          appBar: _appBar(),
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () =>
                  ref.refresh(tutorProfileProvider(tutorId).future),
              child: async.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(
                        color: AppColors.primaryBlue),
                  ),
                ),
                error: (_, _) =>
                    _hint(shell, '리뷰를 불러오지 못했어요.'),
                data: (profile) {
                  if (profile.reviews.isEmpty) {
                    return _hint(shell, '아직 받은 리뷰가 없어요.');
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      ReviewSummary(shell: shell, profile: profile),
                      const SizedBox(height: 8),
                      Divider(
                          color: shell.cardBorder.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      for (var i = 0; i < profile.reviews.length; i++) ...[
                        _card(context, ref, shell, profile.reviews[i]),
                        if (i != profile.reviews.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: const Text('받은 리뷰',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      );

  Widget _hint(ShellTheme shell, String text) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.star_outline_rounded,
              size: 52,
              color: shell.hintColor.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: shell.hintColor)),
        ],
      );

  Widget _card(
      BuildContext context, WidgetRef ref, ShellTheme shell, TutorReviewItem r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: shell.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.studentName ?? '학생',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: shell.titleColor),
              ),
              const SizedBox(width: 8),
              for (var s = 1; s <= 5; s++)
                Icon(
                  s <= r.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: const Color(0xFFF5A623),
                ),
              const Spacer(),
              Text(_ymd(r.createdAt),
                  style: TextStyle(
                      fontSize: 12, color: shell.hintColor)),
              // 리뷰 id가 있어야(백엔드 재배포 후) 신고 가능.
              if (r.id != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showReportDialog(context, ref, shell, r),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_outlined,
                            size: 14, color: shell.hintColor),
                        const SizedBox(width: 2),
                        Text('신고',
                            style: TextStyle(
                                fontSize: 12, color: shell.hintColor)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if ((r.comment?.trim().isNotEmpty) ?? false) ...[
            const SizedBox(height: 10),
            Text(r.comment!.trim(),
                style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: shell.titleColor)),
          ],
        ],
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context, WidgetRef ref,
      ShellTheme shell, TutorReviewItem r) async {
    const reasons = <({String label, String code})>[
      (label: '허위/사기', code: 'FRAUD'),
      (label: '욕설/모욕', code: 'ABUSE'),
      (label: '부적절한 내용', code: 'INAPPROPRIATE'),
      (label: '스팸/광고', code: 'SPAM'),
      (label: '기타', code: 'ETC'),
    ];
    final detailController = TextEditingController();
    String? selectedCode;
    bool submitting = false;
    final isDark = ref.read(shellDarkModeProvider);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setLocal) {
          Future<void> submit() async {
            final me = ref.read(currentUserProvider);
            if (selectedCode == null ||
                submitting ||
                me == null ||
                r.id == null) {
              return;
            }
            setLocal(() => submitting = true);
            try {
              await MypageRepository().createReport(
                reporterId: me.id,
                reporterType: 'TUTOR',
                targetType: 'REVIEW',
                targetId: r.id!,
                reasons: [selectedCode!],
                description: detailController.text,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('신고가 접수되었습니다.')),
              );
            } catch (_) {
              if (!dialogContext.mounted) return;
              setLocal(() => submitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('신고 접수에 실패했어요. 잠시 후 다시 시도해 주세요.')),
              );
            }
          }

          return AlertDialog(
            backgroundColor: shell.cardBackground,
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('리뷰 신고',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('신고 사유를 선택해 주세요.',
                    style:
                        TextStyle(fontSize: 13.5, color: shell.subtitleColor)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final reason in reasons)
                      ChoiceChip(
                        label: Text(reason.label),
                        selected: selectedCode == reason.code,
                        onSelected: (_) =>
                            setLocal(() => selectedCode = reason.code),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailController,
                  maxLines: 3,
                  maxLength: 500,
                  style: TextStyle(color: shell.titleColor, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '상세 내용 (선택)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    submitting ? null : () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue),
                child: const Text('취소',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              FilledButton(
                onPressed: (selectedCode == null || submitting) ? null : submit,
                style: accentDialogButtonStyle(
                  accent: AppColors.logoutRed,
                  isDark: isDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                ),
                child: const Text('신고',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        });
      },
    );
    detailController.dispose();
  }

  static String _ymd(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}.${two(l.month)}.${two(l.day)}';
  }
}
