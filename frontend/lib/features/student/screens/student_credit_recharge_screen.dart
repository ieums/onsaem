import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/payment_models.dart';
import 'package:ieum/features/student/providers/payment_provider.dart';
import 'package:ieum/features/student/widgets/student_coin_payments_sheet.dart';

String formatWon(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class StudentCreditRechargeScreen extends ConsumerStatefulWidget {
  const StudentCreditRechargeScreen({super.key});

  @override
  ConsumerState<StudentCreditRechargeScreen> createState() =>
      _StudentCreditRechargeScreenState();
}

class _StudentCreditRechargeScreenState
    extends ConsumerState<StudentCreditRechargeScreen> {
  int? _selectedId;
  bool _paying = false;

  /// 보너스가 가장 큰 패키지 id → BEST 배지.
  int? _bestId(List<CoinPackage> pkgs) {
    if (pkgs.isEmpty) return null;
    var best = pkgs.first;
    for (final p in pkgs) {
      if (p.bonusAmount > best.bonusAmount) best = p;
    }
    return best.bonusAmount > 0 ? best.id : null;
  }

  Future<void> _pay(CoinPackage pkg) async {
    final studentId = ref.read(currentUserProvider)?.id;
    if (studentId == null) {
      _snack('로그인이 필요해요.');
      return;
    }
    setState(() => _paying = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      // 1) 충전 결제 시작(대기 결제 생성)
      final payment = await repo.createCoinPayment(
        studentId: studentId,
        coinPackageId: pkg.id,
      );
      // 2) 결제 완료 확인 — 테스트 모드(검증 OFF): merchantId를 그대로 사용.
      //    실결제(모바일/JS SDK) 연동 시 이 자리에서 포트원 결제 후 받은 paymentId를 전달.
      await repo.completeCoinPayment(
        merchantId: payment.merchantId,
        portonePaymentId: payment.merchantId,
      );
      if (!mounted) return;
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(coinTransactionsProvider);
      ref.invalidate(coinPaymentsProvider);
      setState(() => _paying = false);
      _snack('${formatWon(pkg.totalCoin)}P 충전 완료!');
    } catch (_) {
      if (!mounted) return;
      setState(() => _paying = false);
      _snack('충전에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
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
    final balanceAsync = ref.watch(coinBalanceProvider);
    final packagesAsync = ref.watch(coinPackagesProvider);

    return Theme(
      data: theme,
      child: Builder(
        builder: (themedContext) {
          final shell = ShellTheme.of(themedContext);
          final pageBg = Theme.of(themedContext).scaffoldBackgroundColor;

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
                  title: Text(
                    '크레딧 충전',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: shell.titleColor,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: '충전 내역',
                      icon: Icon(Icons.receipt_long_outlined,
                          color: shell.titleColor),
                      onPressed: () => showCoinPaymentsSheet(themedContext),
                    ),
                  ],
                ),
                body: packagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.studentPoint),
                  ),
                  error: (_, _) => Center(
                    child: Text('패키지를 불러오지 못했어요.',
                        style: TextStyle(color: shell.hintColor)),
                  ),
                  data: (packages) {
                    if (packages.isEmpty) {
                      return Center(
                        child: Text('충전 패키지가 없어요.',
                            style: TextStyle(color: shell.hintColor)),
                      );
                    }
                    final bestId = _bestId(packages);
                    _selectedId ??= packages.first.id;
                    final selected = packages.firstWhere(
                      (p) => p.id == _selectedId,
                      orElse: () => packages.first,
                    );
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _balanceCard(balanceAsync),
                                const SizedBox(height: 22),
                                _sectionTitle(shell, '충전 금액 선택'),
                                const SizedBox(height: 10),
                                for (var i = 0; i < packages.length; i++) ...[
                                  _packageCard(
                                    shell: shell,
                                    isDark: isDark,
                                    pkg: packages[i],
                                    selected: _selectedId == packages[i].id,
                                    isBest: packages[i].id == bestId,
                                    onTap: () => setState(
                                        () => _selectedId = packages[i].id),
                                  ),
                                  if (i < packages.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ),
                        ColoredBox(
                          color: pageBg,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 12),
                              child: SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed:
                                      _paying ? null : () => _pay(selected),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.studentPoint,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    '${formatWon(selected.price)}원 결제하기',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_paying)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55000000),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(ShellTheme shell, String title) => Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: shell.titleColor,
        ),
      );

  Widget _balanceCard(AsyncValue<CoinBalance?> balanceAsync) {
    final text = balanceAsync.maybeWhen(
      data: (b) => b == null ? '-' : formatWon(b.availableBalance),
      orElse: () => '…',
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.studentPoint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 보유 크레딧',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$text P',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageCard({
    required ShellTheme shell,
    required bool isDark,
    required CoinPackage pkg,
    required bool selected,
    required bool isBest,
    required VoidCallback onTap,
  }) {
    return Material(
      color: shell.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.studentPoint : shell.cardBorder,
          width: selected ? 1.8 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${formatWon(pkg.totalCoin)}P',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: shell.titleColor,
                          ),
                        ),
                        if (pkg.bonusAmount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '+${formatWon(pkg.bonusAmount)}P',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.incomeGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${formatWon(pkg.price)}원',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: shell.hintColor,
                          ),
                        ),
                        if (isBest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.studentPoint
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'BEST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.studentPoint,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.studentPoint : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.studentPoint : shell.cardBorder,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
