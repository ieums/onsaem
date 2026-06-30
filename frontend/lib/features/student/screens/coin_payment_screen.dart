import 'package:flutter/material.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';

import 'package:ieum/core/config/portone_config.dart';

/// PortOne V2 결제창 화면.
///
/// 충전 화면에서 `Navigator.push`로 띄우고, 결과([PaymentResponse])를 pop으로 돌려준다.
/// - 성공: `result.code == null` → 호출부가 백엔드 confirm(검증)으로 확정.
/// - 실패/취소: `result.code != null` 또는 `null` 반환.
class CoinPaymentScreen extends StatelessWidget {
  const CoinPaymentScreen({
    super.key,
    required this.paymentId,
    required this.orderName,
    required this.amount,
  });

  /// 백엔드에서 발급한 결제 식별자(merchantId) — PortOne paymentId로 그대로 사용.
  final String paymentId;
  final String orderName;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return PortonePayment(
      appBar: AppBar(title: const Text('결제')),
      initialChild: const Center(child: CircularProgressIndicator()),
      data: PaymentRequest(
        storeId: PortoneConfig.storeId,
        channelKey: PortoneConfig.channelKey,
        paymentId: paymentId,
        orderName: orderName,
        totalAmount: amount,
        currency: Currency.KRW,
        payMethod: PaymentPayMethod.CARD,
        appScheme: PortoneConfig.appScheme,
      ),
      callback: (PaymentResponse result) {
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      onError: (Object? error) {
        debugPrint('[PortOne] 결제 오류: $error');
        if (!context.mounted) return;
        Navigator.of(context).pop(null);
      },
    );
  }
}
