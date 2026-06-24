// 결제(payment) 도메인 모델.
// 백엔드 PaymentController는 ResponseEntity[X]를 직접 반환(ApiResponse 래핑 아님)
// → 레포지토리에서 res.data를 그대로 파싱한다.

int _asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
int? _asIntN(dynamic v) => (v as num?)?.toInt();
DateTime? _asDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v as String);

/// 코인 잔액.
class CoinBalance {
  const CoinBalance({
    required this.studentId,
    required this.balance,
    required this.availableBalance,
  });

  final int studentId;
  final int balance;
  final int availableBalance;

  factory CoinBalance.fromJson(Map<String, dynamic> j) => CoinBalance(
        studentId: _asInt(j['studentId']),
        balance: _asInt(j['balance']),
        availableBalance: _asInt(j['availableBalance']),
      );
}

/// 코인 충전 패키지.
class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.coinAmount,
    required this.bonusAmount,
    required this.totalCoin,
  });

  final int id;
  final String name;
  final int price; // 원
  final int coinAmount;
  final int bonusAmount;
  final int totalCoin;

  factory CoinPackage.fromJson(Map<String, dynamic> j) => CoinPackage(
        id: _asInt(j['id']),
        name: (j['name'] as String?) ?? '',
        price: _asInt(j['price']),
        coinAmount: _asInt(j['coinAmount']),
        bonusAmount: _asInt(j['bonusAmount']),
        totalCoin: _asInt(j['totalCoin']),
      );
}

/// 코인 거래 내역(적립/사용/환불 등).
class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.type,
    required this.typeDisplayName,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.createdAt,
  });

  final int id;
  final String type;
  final String typeDisplayName;
  final int amount; // +적립 / -사용
  final int balanceAfter;
  final String? description;
  final DateTime? createdAt;

  factory CoinTransaction.fromJson(Map<String, dynamic> j) => CoinTransaction(
        id: _asInt(j['id']),
        type: (j['type'] as String?) ?? '',
        typeDisplayName: (j['typeDisplayName'] as String?) ?? '',
        amount: _asInt(j['amount']),
        balanceAfter: _asInt(j['balanceAfter']),
        description: j['description'] as String?,
        createdAt: _asDate(j['createdAt']),
      );
}

/// 결제 건(충전/구독 공통).
class PaymentInfo {
  const PaymentInfo({
    required this.id,
    required this.merchantId,
    required this.amount,
    this.coinAmount,
    this.bonusCoinAmount,
    this.productName,
    this.status,
    this.method,
    this.createdAt,
    this.completedAt,
  });

  final int id;
  final String merchantId; // 포트원 결제 시작에 사용
  final int amount; // 원
  final int? coinAmount;
  final int? bonusCoinAmount;
  final String? productName;
  final String? status;
  final String? method;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory PaymentInfo.fromJson(Map<String, dynamic> j) => PaymentInfo(
        id: _asInt(j['id']),
        merchantId: (j['merchantId'] as String?) ?? '',
        amount: _asInt(j['amount']),
        coinAmount: _asIntN(j['coinAmount']),
        bonusCoinAmount: _asIntN(j['bonusCoinAmount']),
        productName: j['productName'] as String?,
        status: j['status'] as String?,
        method: j['method'] as String?,
        createdAt: _asDate(j['createdAt']),
        completedAt: _asDate(j['completedAt']),
      );
}

/// 구독 플랜.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.discountPercent,
  });

  final int id;
  final String name;
  final int price;
  final int durationDays;
  final int discountPercent;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
        id: _asInt(j['id']),
        name: (j['name'] as String?) ?? '',
        price: _asInt(j['price']),
        durationDays: _asInt(j['durationDays']),
        discountPercent: _asInt(j['discountPercent']),
      );
}

/// 내 구독 상태.
class Subscription {
  const Subscription({
    required this.id,
    required this.studentId,
    required this.planId,
    required this.paidPrice,
    this.startDate,
    this.endDate,
    required this.autoRenew,
    required this.active,
    required this.valid,
    this.createdAt,
  });

  final int id;
  final int studentId;
  final int planId;
  final int paidPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final bool active;
  final bool valid;
  final DateTime? createdAt;

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: _asInt(j['id']),
        studentId: _asInt(j['studentId']),
        planId: _asInt(j['planId']),
        paidPrice: _asInt(j['paidPrice']),
        startDate: _asDate(j['startDate']),
        endDate: _asDate(j['endDate']),
        autoRenew: j['autoRenew'] as bool? ?? false,
        active: j['active'] as bool? ?? false,
        valid: j['valid'] as bool? ?? false,
        createdAt: _asDate(j['createdAt']),
      );
}
