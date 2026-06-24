import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/payment_models.dart';
import 'package:ieum/features/student/providers/payment_provider.dart';

String _won(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String _date(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}.${two(l.month)}.${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}

({String label, Color color}) _statusChip(String? s) => switch (s) {
      'COMPLETED' => (label: '충전 완료', color: AppColors.incomeGreen),
      'REFUNDED' => (label: '환불됨', color: const Color(0xFF6B7280)),
      'CANCELED' => (label: '취소', color: const Color(0xFF6B7280)),
      'PENDING' => (label: '대기', color: const Color(0xFFE8A33D)),
      'FAILED' => (label: '실패', color: AppColors.logoutRed),
      _ => (label: s ?? '-', color: const Color(0xFF6B7280)),
    };

/// 충전 내역 + 환불 시트.
void showCoinPaymentsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _CoinPaymentsSheet(),
  );
}

class _CoinPaymentsSheet extends ConsumerStatefulWidget {
  const _CoinPaymentsSheet();

  @override
  ConsumerState<_CoinPaymentsSheet> createState() => _CoinPaymentsSheetState();
}

class _CoinPaymentsSheetState extends ConsumerState<_CoinPaymentsSheet> {
  bool _busy = false;

  Future<void> _refund(PaymentInfo p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('충전 환불'),
        content: Text(
            '${_won(p.amount)}원 결제를 환불할까요?\n충전됐던 코인이 회수돼요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('환불')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(paymentRepositoryProvider).refundCoinPayment(p.id);
      if (!mounted) return;
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(coinTransactionsProvider);
      ref.invalidate(coinPaymentsProvider);
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('환불됐어요.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('환불에 실패했어요. 환불 가능 기간을 확인해 주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final payments = ref.watch(coinPaymentsProvider).valueOrNull ?? const [];

    return Stack(
      children: [
        Padding(
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
                    color: shell.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('충전 내역',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: shell.titleColor)),
              const SizedBox(height: 12),
              if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text('충전 내역이 없어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: shell.hintColor)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: payments.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 18, color: shell.dividerColor),
                    itemBuilder: (_, i) => _row(shell, payments[i]),
                  ),
                ),
            ],
          ),
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x44000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _row(ShellTheme shell, PaymentInfo p) {
    final st = _statusChip(p.status);
    final refundable = p.status == 'COMPLETED';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(p.productName ?? '코인 충전',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: shell.titleColor)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: st.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(st.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: st.color)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${_won(p.amount)}원 · ${_date(p.completedAt ?? p.createdAt)}',
                style: TextStyle(fontSize: 12, color: shell.hintColor),
              ),
            ],
          ),
        ),
        if (refundable)
          TextButton(
            onPressed: _busy ? null : () => _refund(p),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.studentPoint,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('환불',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}
