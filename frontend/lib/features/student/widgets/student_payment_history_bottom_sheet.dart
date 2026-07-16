import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/payment_models.dart';
import 'package:ieum/features/student/providers/payment_provider.dart';

/// 한 행 높이 × 5건까지 고정 노출, 그 이상은 스크롤
const _kHistoryRowHeight = 64.0;
const _kHistoryVisibleRows = 5;

String _won(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String _txDate(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}.${two(l.month)}.${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}

String _txTitle(CoinTransaction t) =>
    t.typeDisplayName.isNotEmpty ? t.typeDisplayName : (t.description ?? '거래');

void showStudentPaymentHistoryBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final sheetShell = ShellTheme.of(sheetContext);
          final history =
              ref.watch(coinTransactionsProvider).valueOrNull ?? const [];
          final bottom = MediaQuery.paddingOf(sheetContext).bottom;
          final listHeight = _kHistoryRowHeight *
              (history.length < _kHistoryVisibleRows
                  ? history.length
                  : _kHistoryVisibleRows);

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetShell.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '결제 내역',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: sheetShell.titleColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close_rounded, color: sheetShell.hintColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '총 ${history.length}건',
                  style: TextStyle(fontSize: 13, color: sheetShell.hintColor),
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      '결제 내역이 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: sheetShell.hintColor),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: sheetShell.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sheetShell.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: listHeight,
                      child: history.length <= _kHistoryVisibleRows
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < history.length; i++)
                                  _HistoryRow(
                                    shell: sheetShell,
                                    entry: history[i],
                                    showDivider: i > 0,
                                  ),
                              ],
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: history.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: sheetShell.dividerColor,
                              ),
                              itemBuilder: (context, index) => _HistoryRow(
                                shell: sheetShell,
                                entry: history[index],
                                showDivider: false,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.shell,
    required this.entry,
    required this.showDivider,
  });

  final ShellTheme shell;
  final CoinTransaction entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider) Divider(height: 1, color: shell.dividerColor),
        SizedBox(
          height: _kHistoryRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _txTitle(entry),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: shell.titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _txDate(entry.createdAt),
                        style: TextStyle(fontSize: 12, color: shell.hintColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${entry.amount >= 0 ? '+' : '-'}${_won(entry.amount)}P',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: entry.amount >= 0
                        ? AppColors.incomeGreen
                        : shell.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 자동결제 시트 「결제 내역」 탭용 미리보기 + 전체 보기
class StudentPaymentHistoryTabPanel extends ConsumerWidget {
  const StudentPaymentHistoryTabPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ShellTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history =
        ref.watch(coinTransactionsProvider).valueOrNull ?? const [];
    final preview = history.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (preview.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              '아직 결제 내역이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: shell.hintColor),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? shell.detailBackground : shell.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: shell.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < preview.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: shell.dividerColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _txTitle(preview[i]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: shell.titleColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _txDate(preview[i].createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: shell.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${preview[i].amount >= 0 ? '+' : '-'}${_won(preview[i].amount)}P',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: preview[i].amount >= 0
                                ? AppColors.incomeGreen
                                : shell.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: () => showStudentPaymentHistoryBottomSheet(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.studentInk,
              side: const BorderSide(color: AppColors.studentInk, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              history.length > _kHistoryVisibleRows
                  ? '결제 내역 전체 보기 (${history.length}건)'
                  : '결제 내역 전체 보기',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
