import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';

import 'package:ieum/core/config/portone_config.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';

/// PortOne V2 결제창 화면.
///
/// 충전 화면에서 `Navigator.push`로 띄우고, 결과([PaymentResponse])를 pop으로 돌려준다.
/// - 성공: `result.code == null` → 호출부가 백엔드 confirm(검증)으로 확정.
/// - 실패/취소: `result.code != null` 또는 `null` 반환.
class CoinPaymentScreen extends ConsumerWidget {
  const CoinPaymentScreen({
    super.key,
    required this.paymentId,
    required this.orderName,
    required this.amount,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  /// 백엔드에서 발급한 결제 식별자(merchantId) — PortOne paymentId로 그대로 사용.
  final String paymentId;
  final String orderName;
  final int amount;

  /// 구매자 정보 — 이니시스(KG이니시스) V2 등 일부 PG는 이름이 필수.
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(shellDarkModeProvider);
    final Color bg =
        isDark ? AppColors.shellScaffoldDark : AppColors.studentScaffoldLight;
    final Color fg = isDark ? Colors.white : const Color(0xFF1A1A1A);
    return PortonePayment(
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: fg),
        title: Text(
          '결제',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
      initialChild: const Center(
        child: CircularProgressIndicator(color: AppColors.studentPoint),
      ),
      data: PaymentRequest(
        storeId: PortoneConfig.storeId,
        channelKey: PortoneConfig.channelKey,
        paymentId: paymentId,
        orderName: orderName,
        totalAmount: amount,
        currency: Currency.KRW,
        payMethod: PaymentPayMethod.CARD,
        appScheme: PortoneConfig.appScheme,
        customer: Customer(
          fullName: customerName,
          phoneNumber: customerPhone,
          email: customerEmail,
        ),
      ),
      callback: (PaymentResponse result) {
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      onError: (Object? error) {
        debugPrint('[PortOne] 결제 오류: $error');
        if (!context.mounted) return;
        // 에러는 그대로 돌려보내 호출부가 '취소'와 '오류'를 구분해 표시하게 한다.
        Navigator.of(context).pop(error ?? '알 수 없는 결제 오류가 발생했어요.');
      },
    );
  }
}
