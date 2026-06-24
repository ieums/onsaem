import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
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

String _ymd(DateTime? d) {
  if (d == null) return '-';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}.${two(l.month)}.${two(l.day)}';
}

class StudentSubscriptionScreen extends ConsumerStatefulWidget {
  const StudentSubscriptionScreen({super.key});

  @override
  ConsumerState<StudentSubscriptionScreen> createState() =>
      _StudentSubscriptionScreenState();
}

class _StudentSubscriptionScreenState
    extends ConsumerState<StudentSubscriptionScreen> {
  bool _autoRenew = true;
  bool _busy = false;

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final studentId = ref.read(currentUserProvider)?.id;
    if (studentId == null) return _snack('로그인이 필요해요.');
    setState(() => _busy = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final payment = await repo.createSubscriptionPayment(
        studentId: studentId,
        subscriptionPlanId: plan.id,
        autoRenew: _autoRenew,
      );
      // 테스트 모드(검증 OFF): merchantId를 paymentId로 그대로 사용.
      await repo.completeSubscriptionPayment(
        merchantId: payment.merchantId,
        portonePaymentId: payment.merchantId,
        autoRenew: _autoRenew,
      );
      if (!mounted) return;
      ref.invalidate(mySubscriptionProvider);
      setState(() => _busy = false);
      _snack('${plan.name} 구독이 시작됐어요.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('구독에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> _cancel() async {
    final studentId = ref.read(currentUserProvider)?.id;
    if (studentId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('구독 해지'),
        content: const Text('정말 구독을 해지할까요? 남은 기간까지는 이용할 수 있어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('해지')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(paymentRepositoryProvider).cancelSubscription(studentId);
      if (!mounted) return;
      ref.invalidate(mySubscriptionProvider);
      setState(() => _busy = false);
      _snack('구독을 해지했어요.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('해지에 실패했어요.');
    }
  }

  Future<void> _toggleAuto(bool value) async {
    final studentId = ref.read(currentUserProvider)?.id;
    if (studentId == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .toggleAutoRenew(studentId: studentId, autoRenew: value);
      if (!mounted) return;
      ref.invalidate(mySubscriptionProvider);
      setState(() => _busy = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('자동 갱신 변경에 실패했어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
    final subAsync = ref.watch(mySubscriptionProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Theme(
      data: theme,
      child: Builder(
        builder: (themedContext) {
          final shell = ShellTheme.of(themedContext);
          final pageBg = Theme.of(themedContext).scaffoldBackgroundColor;
          final sub = subAsync.valueOrNull;
          final hasActive = sub != null && sub.valid;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: pageBg,
                appBar: AppBar(
                  backgroundColor: pageBg,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 20, color: shell.titleColor),
                    onPressed: () => themedContext.pop(),
                  ),
                  title: Text('구독',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: shell.titleColor)),
                ),
                body: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (hasActive) _currentCard(shell, sub),
                    if (hasActive) const SizedBox(height: 24),
                    Text(
                      hasActive ? '플랜 변경' : '구독 플랜',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    plansAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.studentPoint)),
                      ),
                      error: (_, _) => Text('플랜을 불러오지 못했어요.',
                          style: TextStyle(color: shell.hintColor)),
                      data: (plans) => Column(
                        children: [
                          for (final p in plans) ...[
                            _planCard(shell, p),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    if (!hasActive) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.studentPoint,
                        title: Text('자동 갱신',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: shell.titleColor)),
                        subtitle: Text('기간 종료 시 자동으로 재결제돼요.',
                            style:
                                TextStyle(fontSize: 12, color: shell.hintColor)),
                        value: _autoRenew,
                        onChanged: (v) => setState(() => _autoRenew = v),
                      ),
                    ],
                  ],
                ),
              ),
              if (_busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55000000),
                    child:
                        Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _currentCard(ShellTheme shell, Subscription sub) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.studentPoint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                sub.active ? '구독 이용 중' : '해지 예정 (기간까지 이용 가능)',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '이용 기간  ${_ymd(sub.startDate)} ~ ${_ymd(sub.endDate)}',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: sub.autoRenew,
                      onChanged: _busy ? null : _toggleAuto,
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    Text('자동 갱신',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.95))),
                  ],
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _cancel,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('구독 해지',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planCard(ShellTheme shell, SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor)),
              ),
              if (plan.discountPercent > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.incomeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${plan.discountPercent}% 할인',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.incomeGreen)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${plan.durationDays}일 이용',
              style: TextStyle(fontSize: 13, color: shell.hintColor)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('${_won(plan.price)}원',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: shell.titleColor)),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : () => _subscribe(plan),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.studentPoint,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('구독하기',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
