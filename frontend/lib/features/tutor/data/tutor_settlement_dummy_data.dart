// 강사 정산 더미 데이터.
// API 연동 시 TutorSettlementDummyData.build 호출부만 레포지토리로 교체하면 됩니다.

import 'package:ieum/features/tutor/data/tutor_pricing.dart';

/// 달력·그래프에 쓰는 정산 거래 (더미 / API 공통 형태).
class TutorSettlementCalendarTransaction {
  const TutorSettlementCalendarTransaction({
    required this.date,
    required this.label,
    required this.amount,
    this.filledFromPriorYear = false,
  });

  final DateTime date;
  final String label;
  final int amount;

  /// 오늘 이후 날짜에 작년 데이터를 채워 넣은 경우 true.
  final bool filledFromPriorYear;

  bool get isDeposit => amount > 0;
}

class TutorSettlementTransactionSeed {
  const TutorSettlementTransactionSeed.deposit(
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.amount,
  ) : isWithdraw = false;

  const TutorSettlementTransactionSeed.withdraw(
    this.month,
    this.day,
    this.hour,
    this.amount,
  ) : minute = 0,
      isWithdraw = true;

  final int month;
  final int day;
  final int hour;
  final int minute;
  final int amount;
  final bool isWithdraw;
}

class TutorSettlementDummyData {
  TutorSettlementDummyData._();

  /// 개발용 기준일. 출시 시 `DateTime.now()` 전달.
  static final DateTime referenceDate = DateTime(2026, 5, 21);

  /// 입금 시드 [TutorSettlementTransactionSeed.minute] = 예상 수업 시간(분). 0이면 30분으로 간주.
  static const _defaultDepositClassMinutes = 30;

  /// 구 더미 입금·출금 스케일을 새 요금(문제당 최대 5,000원)에 맞추기 위한 기준.
  static const _legacyDepositCapWon = 35000;
  static const _minWithdrawWon = 5000;
  static const _maxWithdrawWon = 25000;

  /// 입금(문제 정산) 금액 — [TutorPricing.expectedPriceWon]과 동일 규칙.
  static int depositAmountFromSeed(TutorSettlementTransactionSeed seed) {
    final minutes =
        seed.minute > 0 ? seed.minute : _defaultDepositClassMinutes;
    return TutorPricing.expectedPriceWon(minutes);
  }

  /// 출금 금액 — 누적 잔액 규모에 맞게 구 더미 대비 축소.
  static int withdrawAmountFromSeed(TutorSettlementTransactionSeed seed) {
    final scaled = (seed.amount * TutorPricing.maxPricePerProblemWon) /
        _legacyDepositCapWon;
    final rounded = ((scaled + 250) ~/ 500) * 500;
    return rounded.clamp(_minWithdrawWon, _maxWithdrawWon);
  }

  static int resolvedAmount(TutorSettlementTransactionSeed seed) =>
      seed.isWithdraw ? withdrawAmountFromSeed(seed) : depositAmountFromSeed(seed);

  static const currentYearSeeds = <TutorSettlementTransactionSeed>[
    TutorSettlementTransactionSeed.deposit(1, 3, 10, 20, 13500),
    TutorSettlementTransactionSeed.deposit(1, 6, 14, 10, 18200),
    TutorSettlementTransactionSeed.deposit(1, 8, 11, 5, 15800),
    TutorSettlementTransactionSeed.deposit(1, 10, 16, 40, 22100),
    TutorSettlementTransactionSeed.deposit(1, 13, 9, 30, 12400),
    TutorSettlementTransactionSeed.deposit(1, 15, 19, 15, 19600),
    TutorSettlementTransactionSeed.withdraw(1, 16, 18, 45000),
    TutorSettlementTransactionSeed.deposit(1, 20, 13, 0, 17250),
    TutorSettlementTransactionSeed.deposit(1, 22, 10, 45, 14800),
    TutorSettlementTransactionSeed.deposit(1, 24, 15, 20, 20500),
    TutorSettlementTransactionSeed.deposit(1, 27, 11, 10, 16200),
    TutorSettlementTransactionSeed.deposit(1, 29, 17, 35, 18900),
    TutorSettlementTransactionSeed.deposit(2, 2, 9, 15, 19800),
    TutorSettlementTransactionSeed.deposit(2, 4, 14, 0, 22500),
    TutorSettlementTransactionSeed.deposit(2, 5, 18, 30, 17200),
    TutorSettlementTransactionSeed.deposit(2, 7, 10, 40, 24100),
    TutorSettlementTransactionSeed.deposit(2, 10, 13, 20, 20800),
    TutorSettlementTransactionSeed.deposit(2, 12, 16, 5, 23400),
    TutorSettlementTransactionSeed.deposit(2, 14, 11, 50, 19100),
    TutorSettlementTransactionSeed.withdraw(2, 15, 20, 60000),
    TutorSettlementTransactionSeed.deposit(2, 18, 9, 0, 24700),
    TutorSettlementTransactionSeed.deposit(2, 19, 15, 45, 21300),
    TutorSettlementTransactionSeed.deposit(2, 21, 12, 10, 25800),
    TutorSettlementTransactionSeed.deposit(2, 24, 17, 0, 22600),
    TutorSettlementTransactionSeed.deposit(2, 26, 10, 25, 23900),
    TutorSettlementTransactionSeed.deposit(2, 28, 14, 40, 21500),
    TutorSettlementTransactionSeed.deposit(3, 2, 10, 0, 16800),
    TutorSettlementTransactionSeed.deposit(3, 4, 14, 20, 19200),
    TutorSettlementTransactionSeed.deposit(3, 6, 11, 40, 21500),
    TutorSettlementTransactionSeed.deposit(3, 8, 16, 10, 20100),
    TutorSettlementTransactionSeed.deposit(3, 9, 9, 30, 24800),
    TutorSettlementTransactionSeed.deposit(3, 10, 13, 15, 27500),
    TutorSettlementTransactionSeed.deposit(3, 11, 18, 0, 26200),
    TutorSettlementTransactionSeed.deposit(3, 12, 10, 45, 28900),
    TutorSettlementTransactionSeed.deposit(3, 13, 15, 20, 30100),
    TutorSettlementTransactionSeed.withdraw(3, 14, 19, 85000),
    TutorSettlementTransactionSeed.deposit(3, 15, 9, 0, 31800),
    TutorSettlementTransactionSeed.deposit(3, 16, 14, 30, 29400),
    TutorSettlementTransactionSeed.deposit(3, 17, 11, 10, 27600),
    TutorSettlementTransactionSeed.deposit(3, 18, 17, 40, 30500),
    TutorSettlementTransactionSeed.deposit(3, 19, 10, 20, 28800),
    TutorSettlementTransactionSeed.deposit(3, 20, 13, 50, 27100),
    TutorSettlementTransactionSeed.deposit(3, 21, 16, 5, 25600),
    TutorSettlementTransactionSeed.deposit(3, 23, 9, 15, 24200),
    TutorSettlementTransactionSeed.deposit(3, 24, 14, 0, 26800),
    TutorSettlementTransactionSeed.deposit(3, 25, 11, 35, 25100),
    TutorSettlementTransactionSeed.deposit(3, 26, 18, 20, 23400),
    TutorSettlementTransactionSeed.deposit(3, 27, 10, 50, 21900),
    TutorSettlementTransactionSeed.deposit(3, 30, 15, 10, 18700),
    TutorSettlementTransactionSeed.deposit(4, 1, 10, 0, 16800),
    TutorSettlementTransactionSeed.deposit(4, 3, 14, 25, 19200),
    TutorSettlementTransactionSeed.deposit(4, 5, 11, 40, 21500),
    TutorSettlementTransactionSeed.deposit(4, 7, 16, 10, 17800),
    TutorSettlementTransactionSeed.deposit(4, 9, 9, 20, 20400),
    TutorSettlementTransactionSeed.deposit(4, 11, 13, 55, 23600),
    TutorSettlementTransactionSeed.deposit(4, 14, 18, 30, 18900),
    TutorSettlementTransactionSeed.withdraw(4, 15, 20, 55000),
    TutorSettlementTransactionSeed.deposit(4, 17, 10, 15, 22100),
    TutorSettlementTransactionSeed.deposit(4, 19, 15, 0, 19800),
    TutorSettlementTransactionSeed.deposit(4, 21, 11, 45, 25200),
    TutorSettlementTransactionSeed.deposit(4, 23, 17, 20, 20700),
    TutorSettlementTransactionSeed.deposit(4, 25, 9, 30, 17400),
    TutorSettlementTransactionSeed.deposit(4, 26, 14, 40, 24100),
    TutorSettlementTransactionSeed.deposit(4, 28, 12, 5, 19600),
    TutorSettlementTransactionSeed.deposit(4, 30, 16, 50, 22800),
    TutorSettlementTransactionSeed.deposit(5, 5, 13, 25, 18750),
    TutorSettlementTransactionSeed.deposit(5, 5, 17, 5, 12000),
    TutorSettlementTransactionSeed.withdraw(5, 5, 20, 40000),
    TutorSettlementTransactionSeed.deposit(5, 7, 9, 5, 24000),
    TutorSettlementTransactionSeed.deposit(5, 7, 14, 50, 17250),
    TutorSettlementTransactionSeed.deposit(5, 10, 10, 15, 30000),
    TutorSettlementTransactionSeed.deposit(5, 10, 16, 40, 16250),
    TutorSettlementTransactionSeed.withdraw(5, 10, 21, 55000),
    TutorSettlementTransactionSeed.deposit(5, 11, 18, 5, 16250),
    TutorSettlementTransactionSeed.deposit(5, 12, 14, 5, 18000),
    TutorSettlementTransactionSeed.deposit(5, 12, 18, 40, 15500),
    TutorSettlementTransactionSeed.deposit(5, 12, 21, 10, 22500),
    TutorSettlementTransactionSeed.withdraw(5, 13, 9, 80000),
    TutorSettlementTransactionSeed.deposit(5, 14, 10, 20, 30000),
    TutorSettlementTransactionSeed.deposit(5, 14, 15, 10, 21250),
    TutorSettlementTransactionSeed.deposit(5, 15, 11, 30, 14000),
    TutorSettlementTransactionSeed.deposit(5, 15, 16, 45, 12500),
    TutorSettlementTransactionSeed.withdraw(5, 16, 11, 50000),
    TutorSettlementTransactionSeed.deposit(5, 17, 10, 0, 26500),
    TutorSettlementTransactionSeed.deposit(5, 17, 16, 25, 19800),
    TutorSettlementTransactionSeed.deposit(5, 18, 10, 5, 16250),
    TutorSettlementTransactionSeed.deposit(5, 18, 14, 30, 25000),
    TutorSettlementTransactionSeed.deposit(5, 18, 19, 15, 18750),
    TutorSettlementTransactionSeed.withdraw(5, 18, 22, 35000),
    TutorSettlementTransactionSeed.deposit(5, 19, 14, 20, 23800),
    TutorSettlementTransactionSeed.deposit(5, 20, 9, 30, 28000),
    TutorSettlementTransactionSeed.deposit(5, 20, 13, 15, 19500),
    TutorSettlementTransactionSeed.deposit(5, 20, 17, 50, 14250),
    TutorSettlementTransactionSeed.withdraw(5, 20, 20, 60000),
    TutorSettlementTransactionSeed.deposit(5, 21, 11, 40, 27400),
  ];

  static const priorYearSeeds = <TutorSettlementTransactionSeed>[
    TutorSettlementTransactionSeed.deposit(1, 3, 10, 20, 13500),
    TutorSettlementTransactionSeed.deposit(1, 6, 14, 10, 18200),
    TutorSettlementTransactionSeed.deposit(1, 8, 11, 5, 15800),
    TutorSettlementTransactionSeed.deposit(1, 10, 16, 40, 22100),
    TutorSettlementTransactionSeed.deposit(1, 13, 9, 30, 12400),
    TutorSettlementTransactionSeed.deposit(1, 15, 19, 15, 19600),
    TutorSettlementTransactionSeed.withdraw(1, 16, 18, 45000),
    TutorSettlementTransactionSeed.deposit(1, 20, 13, 0, 17250),
    TutorSettlementTransactionSeed.deposit(1, 22, 10, 45, 14800),
    TutorSettlementTransactionSeed.deposit(1, 24, 15, 20, 20500),
    TutorSettlementTransactionSeed.deposit(1, 27, 11, 10, 16200),
    TutorSettlementTransactionSeed.deposit(1, 29, 17, 35, 18900),
    TutorSettlementTransactionSeed.deposit(2, 2, 9, 15, 19800),
    TutorSettlementTransactionSeed.deposit(2, 4, 14, 0, 22500),
    TutorSettlementTransactionSeed.deposit(2, 5, 18, 30, 17200),
    TutorSettlementTransactionSeed.deposit(2, 7, 10, 40, 24100),
    TutorSettlementTransactionSeed.deposit(2, 10, 13, 20, 20800),
    TutorSettlementTransactionSeed.deposit(2, 12, 16, 5, 23400),
    TutorSettlementTransactionSeed.deposit(2, 14, 11, 50, 19100),
    TutorSettlementTransactionSeed.withdraw(2, 15, 20, 60000),
    TutorSettlementTransactionSeed.deposit(2, 18, 9, 0, 24700),
    TutorSettlementTransactionSeed.deposit(2, 19, 15, 45, 21300),
    TutorSettlementTransactionSeed.deposit(2, 21, 12, 10, 25800),
    TutorSettlementTransactionSeed.deposit(2, 24, 17, 0, 22600),
    TutorSettlementTransactionSeed.deposit(2, 26, 10, 25, 23900),
    TutorSettlementTransactionSeed.deposit(2, 28, 14, 40, 21500),
    TutorSettlementTransactionSeed.deposit(3, 2, 10, 0, 16800),
    TutorSettlementTransactionSeed.deposit(3, 4, 14, 20, 19200),
    TutorSettlementTransactionSeed.deposit(3, 6, 11, 40, 21500),
    TutorSettlementTransactionSeed.deposit(3, 8, 16, 10, 20100),
    TutorSettlementTransactionSeed.deposit(3, 9, 9, 30, 24800),
    TutorSettlementTransactionSeed.deposit(3, 10, 13, 15, 27500),
    TutorSettlementTransactionSeed.deposit(3, 11, 18, 0, 26200),
    TutorSettlementTransactionSeed.deposit(3, 12, 10, 45, 28900),
    TutorSettlementTransactionSeed.deposit(3, 13, 15, 20, 30100),
    TutorSettlementTransactionSeed.withdraw(3, 14, 19, 85000),
    TutorSettlementTransactionSeed.deposit(3, 15, 9, 0, 31800),
    TutorSettlementTransactionSeed.deposit(3, 16, 14, 30, 29400),
    TutorSettlementTransactionSeed.deposit(3, 17, 11, 10, 27600),
    TutorSettlementTransactionSeed.deposit(3, 18, 17, 40, 30500),
    TutorSettlementTransactionSeed.deposit(3, 19, 10, 20, 28800),
    TutorSettlementTransactionSeed.deposit(3, 20, 13, 50, 27100),
    TutorSettlementTransactionSeed.deposit(3, 21, 16, 5, 25600),
    TutorSettlementTransactionSeed.deposit(3, 23, 9, 15, 24200),
    TutorSettlementTransactionSeed.deposit(3, 24, 14, 0, 26800),
    TutorSettlementTransactionSeed.deposit(3, 25, 11, 35, 25100),
    TutorSettlementTransactionSeed.deposit(3, 26, 18, 20, 23400),
    TutorSettlementTransactionSeed.deposit(3, 27, 10, 50, 21900),
    TutorSettlementTransactionSeed.deposit(3, 30, 15, 10, 18700),
    TutorSettlementTransactionSeed.deposit(4, 1, 10, 0, 16800),
    TutorSettlementTransactionSeed.deposit(4, 3, 14, 25, 19200),
    TutorSettlementTransactionSeed.deposit(4, 5, 11, 40, 21500),
    TutorSettlementTransactionSeed.deposit(4, 7, 16, 10, 17800),
    TutorSettlementTransactionSeed.deposit(4, 9, 9, 20, 20400),
    TutorSettlementTransactionSeed.deposit(4, 11, 13, 55, 23600),
    TutorSettlementTransactionSeed.deposit(4, 14, 18, 30, 18900),
    TutorSettlementTransactionSeed.withdraw(4, 15, 20, 55000),
    TutorSettlementTransactionSeed.deposit(4, 17, 10, 15, 22100),
    TutorSettlementTransactionSeed.deposit(4, 19, 15, 0, 19800),
    TutorSettlementTransactionSeed.deposit(4, 21, 11, 45, 25200),
    TutorSettlementTransactionSeed.deposit(4, 23, 17, 20, 20700),
    TutorSettlementTransactionSeed.deposit(4, 25, 9, 30, 17400),
    TutorSettlementTransactionSeed.deposit(4, 26, 14, 40, 24100),
    TutorSettlementTransactionSeed.deposit(4, 28, 12, 5, 19600),
    TutorSettlementTransactionSeed.deposit(4, 30, 16, 50, 22800),
    TutorSettlementTransactionSeed.deposit(5, 5, 13, 25, 18750),
    TutorSettlementTransactionSeed.deposit(5, 5, 17, 5, 12000),
    TutorSettlementTransactionSeed.withdraw(5, 5, 20, 40000),
    TutorSettlementTransactionSeed.deposit(5, 7, 9, 5, 24000),
    TutorSettlementTransactionSeed.deposit(5, 7, 14, 50, 17250),
    TutorSettlementTransactionSeed.deposit(5, 10, 10, 15, 30000),
    TutorSettlementTransactionSeed.deposit(5, 10, 16, 40, 16250),
    TutorSettlementTransactionSeed.withdraw(5, 10, 21, 55000),
    TutorSettlementTransactionSeed.deposit(5, 11, 18, 5, 16250),
    TutorSettlementTransactionSeed.deposit(5, 12, 14, 5, 18000),
    TutorSettlementTransactionSeed.deposit(5, 12, 18, 40, 15500),
    TutorSettlementTransactionSeed.deposit(5, 12, 21, 10, 22500),
    TutorSettlementTransactionSeed.withdraw(5, 13, 9, 80000),
    TutorSettlementTransactionSeed.deposit(5, 14, 10, 20, 30000),
    TutorSettlementTransactionSeed.deposit(5, 14, 15, 10, 21250),
    TutorSettlementTransactionSeed.deposit(5, 15, 11, 30, 14000),
    TutorSettlementTransactionSeed.deposit(5, 15, 16, 45, 12500),
    TutorSettlementTransactionSeed.withdraw(5, 16, 11, 50000),
    TutorSettlementTransactionSeed.deposit(5, 17, 10, 0, 26500),
    TutorSettlementTransactionSeed.deposit(5, 17, 16, 25, 19800),
    TutorSettlementTransactionSeed.deposit(5, 18, 10, 5, 16250),
    TutorSettlementTransactionSeed.deposit(5, 18, 14, 30, 25000),
    TutorSettlementTransactionSeed.deposit(5, 18, 19, 15, 18750),
    TutorSettlementTransactionSeed.withdraw(5, 18, 22, 35000),
    TutorSettlementTransactionSeed.deposit(5, 19, 14, 20, 23800),
    TutorSettlementTransactionSeed.deposit(5, 20, 9, 30, 28000),
    TutorSettlementTransactionSeed.deposit(5, 20, 13, 15, 19500),
    TutorSettlementTransactionSeed.deposit(5, 20, 17, 50, 14250),
    TutorSettlementTransactionSeed.withdraw(5, 20, 20, 60000),
    TutorSettlementTransactionSeed.deposit(5, 21, 11, 40, 27400),
    TutorSettlementTransactionSeed.deposit(5, 22, 11, 10, 31000),
    TutorSettlementTransactionSeed.deposit(5, 22, 15, 35, 20500),
    TutorSettlementTransactionSeed.deposit(5, 22, 19, 5, 16800),
    TutorSettlementTransactionSeed.deposit(5, 23, 16, 0, 18600),
    TutorSettlementTransactionSeed.deposit(5, 24, 10, 25, 15200),
    TutorSettlementTransactionSeed.deposit(5, 25, 11, 20, 22000),
    TutorSettlementTransactionSeed.deposit(5, 25, 15, 45, 17500),
    TutorSettlementTransactionSeed.withdraw(5, 25, 19, 45000),
    TutorSettlementTransactionSeed.deposit(6, 1, 10, 0, 20400),
    TutorSettlementTransactionSeed.deposit(6, 3, 14, 25, 22800),
    TutorSettlementTransactionSeed.deposit(6, 5, 11, 40, 24100),
    TutorSettlementTransactionSeed.deposit(6, 6, 16, 10, 25600),
    TutorSettlementTransactionSeed.deposit(6, 7, 9, 20, 27200),
    TutorSettlementTransactionSeed.deposit(6, 8, 13, 45, 29800),
    TutorSettlementTransactionSeed.deposit(6, 9, 18, 0, 28500),
    TutorSettlementTransactionSeed.deposit(6, 10, 10, 30, 31100),
    TutorSettlementTransactionSeed.deposit(6, 11, 15, 15, 30400),
    TutorSettlementTransactionSeed.withdraw(6, 12, 20, 90000),
    TutorSettlementTransactionSeed.deposit(6, 13, 9, 0, 32500),
    TutorSettlementTransactionSeed.deposit(6, 14, 14, 40, 31800),
    TutorSettlementTransactionSeed.deposit(6, 15, 11, 10, 29600),
    TutorSettlementTransactionSeed.deposit(6, 16, 17, 25, 30900),
    TutorSettlementTransactionSeed.deposit(6, 17, 10, 50, 28700),
    TutorSettlementTransactionSeed.deposit(6, 18, 13, 20, 27400),
    TutorSettlementTransactionSeed.deposit(6, 19, 16, 5, 26100),
    TutorSettlementTransactionSeed.deposit(6, 20, 9, 35, 24800),
    TutorSettlementTransactionSeed.deposit(6, 22, 14, 0, 23500),
    TutorSettlementTransactionSeed.deposit(6, 24, 11, 45, 22200),
    TutorSettlementTransactionSeed.deposit(6, 26, 15, 30, 21800),
    TutorSettlementTransactionSeed.deposit(6, 28, 10, 15, 20600),
    TutorSettlementTransactionSeed.deposit(7, 2, 11, 20, 15800),
    TutorSettlementTransactionSeed.deposit(7, 7, 14, 0, 17200),
    TutorSettlementTransactionSeed.deposit(7, 10, 10, 40, 16500),
    TutorSettlementTransactionSeed.deposit(7, 14, 16, 30, 18100),
    TutorSettlementTransactionSeed.withdraw(7, 15, 18, 40000),
    TutorSettlementTransactionSeed.deposit(7, 18, 9, 50, 17400),
    TutorSettlementTransactionSeed.deposit(7, 22, 13, 15, 16800),
    TutorSettlementTransactionSeed.deposit(7, 25, 11, 0, 16200),
    TutorSettlementTransactionSeed.deposit(7, 29, 15, 45, 17600),
    TutorSettlementTransactionSeed.deposit(8, 3, 10, 15, 19200),
    TutorSettlementTransactionSeed.deposit(8, 5, 14, 30, 20800),
    TutorSettlementTransactionSeed.deposit(8, 8, 11, 40, 21500),
    TutorSettlementTransactionSeed.deposit(8, 11, 16, 20, 22100),
    TutorSettlementTransactionSeed.deposit(8, 13, 9, 30, 23400),
    TutorSettlementTransactionSeed.deposit(8, 15, 13, 50, 22800),
    TutorSettlementTransactionSeed.withdraw(8, 16, 19, 50000),
    TutorSettlementTransactionSeed.deposit(8, 18, 10, 0, 24100),
    TutorSettlementTransactionSeed.deposit(8, 20, 15, 10, 23600),
    TutorSettlementTransactionSeed.deposit(8, 22, 11, 45, 21900),
    TutorSettlementTransactionSeed.deposit(8, 25, 17, 0, 22500),
    TutorSettlementTransactionSeed.deposit(8, 27, 10, 25, 21200),
    TutorSettlementTransactionSeed.deposit(8, 29, 14, 40, 20700),
    TutorSettlementTransactionSeed.deposit(9, 1, 10, 0, 23800),
    TutorSettlementTransactionSeed.deposit(9, 3, 14, 20, 25200),
    TutorSettlementTransactionSeed.deposit(9, 5, 11, 40, 26400),
    TutorSettlementTransactionSeed.deposit(9, 6, 16, 10, 27800),
    TutorSettlementTransactionSeed.deposit(9, 7, 9, 30, 29100),
    TutorSettlementTransactionSeed.deposit(9, 8, 13, 15, 30500),
    TutorSettlementTransactionSeed.deposit(9, 9, 18, 0, 31200),
    TutorSettlementTransactionSeed.deposit(9, 10, 10, 45, 32800),
    TutorSettlementTransactionSeed.deposit(9, 11, 15, 20, 31900),
    TutorSettlementTransactionSeed.withdraw(9, 12, 20, 95000),
    TutorSettlementTransactionSeed.deposit(9, 13, 9, 0, 33400),
    TutorSettlementTransactionSeed.deposit(9, 14, 14, 30, 32100),
    TutorSettlementTransactionSeed.deposit(9, 15, 11, 10, 30700),
    TutorSettlementTransactionSeed.deposit(9, 16, 17, 40, 31500),
    TutorSettlementTransactionSeed.deposit(9, 17, 10, 20, 29800),
    TutorSettlementTransactionSeed.deposit(9, 18, 13, 50, 28600),
    TutorSettlementTransactionSeed.deposit(9, 19, 16, 5, 27200),
    TutorSettlementTransactionSeed.deposit(9, 22, 9, 15, 25800),
    TutorSettlementTransactionSeed.deposit(9, 23, 14, 0, 24500),
    TutorSettlementTransactionSeed.deposit(9, 24, 11, 35, 23100),
    TutorSettlementTransactionSeed.deposit(9, 26, 15, 45, 22400),
    TutorSettlementTransactionSeed.deposit(9, 29, 10, 25, 21800),
    TutorSettlementTransactionSeed.deposit(10, 1, 10, 0, 26800),
    TutorSettlementTransactionSeed.deposit(10, 2, 14, 30, 28100),
    TutorSettlementTransactionSeed.deposit(10, 3, 11, 15, 29400),
    TutorSettlementTransactionSeed.deposit(10, 5, 9, 40, 30200),
    TutorSettlementTransactionSeed.deposit(10, 6, 13, 20, 31500),
    TutorSettlementTransactionSeed.deposit(10, 7, 17, 0, 30800),
    TutorSettlementTransactionSeed.deposit(10, 8, 10, 50, 32100),
    TutorSettlementTransactionSeed.deposit(10, 9, 15, 10, 33400),
    TutorSettlementTransactionSeed.deposit(10, 10, 9, 0, 32800),
    TutorSettlementTransactionSeed.deposit(10, 11, 14, 25, 34100),
    TutorSettlementTransactionSeed.withdraw(10, 12, 20, 100000),
    TutorSettlementTransactionSeed.deposit(10, 13, 11, 40, 33600),
    TutorSettlementTransactionSeed.deposit(10, 14, 16, 15, 34800),
    TutorSettlementTransactionSeed.deposit(10, 15, 10, 30, 35200),
    TutorSettlementTransactionSeed.deposit(10, 16, 13, 55, 34500),
    TutorSettlementTransactionSeed.deposit(10, 17, 18, 20, 33800),
    TutorSettlementTransactionSeed.deposit(10, 19, 9, 15, 33100),
    TutorSettlementTransactionSeed.deposit(10, 20, 14, 0, 32400),
    TutorSettlementTransactionSeed.deposit(10, 21, 11, 45, 31700),
    TutorSettlementTransactionSeed.deposit(10, 22, 17, 30, 32900),
    TutorSettlementTransactionSeed.deposit(10, 23, 10, 20, 32200),
    TutorSettlementTransactionSeed.deposit(10, 24, 15, 50, 31500),
    TutorSettlementTransactionSeed.deposit(10, 26, 9, 35, 30800),
    TutorSettlementTransactionSeed.deposit(10, 27, 13, 10, 30100),
    TutorSettlementTransactionSeed.deposit(10, 28, 16, 40, 29600),
    TutorSettlementTransactionSeed.deposit(10, 30, 11, 25, 28800),
    TutorSettlementTransactionSeed.deposit(11, 2, 9, 0, 34200),
    TutorSettlementTransactionSeed.deposit(11, 3, 13, 30, 35800),
    TutorSettlementTransactionSeed.deposit(11, 4, 10, 15, 35100),
    TutorSettlementTransactionSeed.deposit(11, 5, 15, 40, 36500),
    TutorSettlementTransactionSeed.deposit(11, 6, 9, 20, 37200),
    TutorSettlementTransactionSeed.deposit(11, 7, 14, 0, 36800),
    TutorSettlementTransactionSeed.deposit(11, 8, 11, 45, 37400),
    TutorSettlementTransactionSeed.deposit(11, 9, 16, 30, 38100),
    TutorSettlementTransactionSeed.deposit(11, 10, 10, 0, 37800),
    TutorSettlementTransactionSeed.withdraw(11, 11, 18, 120000),
    TutorSettlementTransactionSeed.deposit(11, 12, 13, 20, 38500),
    TutorSettlementTransactionSeed.deposit(11, 13, 9, 50, 39200),
    TutorSettlementTransactionSeed.deposit(11, 14, 14, 40, 38800),
    TutorSettlementTransactionSeed.deposit(11, 15, 11, 10, 37600),
    TutorSettlementTransactionSeed.deposit(11, 16, 17, 25, 36900),
    TutorSettlementTransactionSeed.deposit(11, 17, 10, 35, 35400),
    TutorSettlementTransactionSeed.deposit(11, 18, 15, 15, 34100),
    TutorSettlementTransactionSeed.deposit(11, 19, 9, 0, 32800),
    TutorSettlementTransactionSeed.deposit(11, 20, 13, 45, 31500),
    TutorSettlementTransactionSeed.deposit(11, 21, 11, 20, 30200),
    TutorSettlementTransactionSeed.deposit(11, 24, 14, 30, 28600),
    TutorSettlementTransactionSeed.deposit(11, 25, 10, 50, 27400),
    TutorSettlementTransactionSeed.deposit(11, 26, 16, 5, 26100),
    TutorSettlementTransactionSeed.deposit(11, 27, 9, 40, 24800),
    TutorSettlementTransactionSeed.deposit(11, 28, 13, 15, 23500),
    TutorSettlementTransactionSeed.deposit(12, 2, 10, 15, 14200),
    TutorSettlementTransactionSeed.deposit(12, 5, 14, 30, 12800),
    TutorSettlementTransactionSeed.deposit(12, 9, 11, 0, 13500),
    TutorSettlementTransactionSeed.withdraw(12, 10, 18, 30000),
    TutorSettlementTransactionSeed.deposit(12, 14, 15, 20, 11800),
    TutorSettlementTransactionSeed.deposit(12, 18, 10, 40, 12400),
  ];

  /// [asOf] 기준으로 거래 목록 생성.
  ///
  /// - 올해·오늘 이전(포함): [currentYearSeeds]
  /// - 올해·오늘 이후: [priorYearSeeds]를 같은 월·일로 채움
  /// - 작년 달력: [priorYearSeeds]를 실제 작년 날짜로
  static List<TutorSettlementCalendarTransaction> build({
    DateTime? asOf,
  }) {
    final ref = _dateOnly(asOf ?? referenceDate);
    final year = ref.year;
    final priorYear = year - 1;
    final out = <TutorSettlementCalendarTransaction>[];

    void addSeeds(
      List<TutorSettlementTransactionSeed> seeds,
      int targetYear, {
      required bool Function(DateTime day) include,
      bool filledFromPriorYear = false,
    }) {
      for (final seed in seeds) {
        final day = _dateOnly(
          DateTime(targetYear, seed.month, seed.day, seed.hour, seed.minute),
        );
        if (!include(day)) continue;
        out.add(
          TutorSettlementCalendarTransaction(
            date: DateTime(
              targetYear,
              seed.month,
              seed.day,
              seed.hour,
              seed.minute,
            ),
            label: seed.isWithdraw ? '출금' : '입금',
            amount: seed.isWithdraw
                ? -resolvedAmount(seed)
                : resolvedAmount(seed),
            filledFromPriorYear: filledFromPriorYear,
          ),
        );
      }
    }

    addSeeds(
      currentYearSeeds,
      year,
      include: (day) => !day.isAfter(ref),
    );
    addSeeds(
      priorYearSeeds,
      year,
      include: (day) => day.isAfter(ref),
      filledFromPriorYear: true,
    );
    addSeeds(
      priorYearSeeds,
      priorYear,
      include: (_) => true,
    );

    return out;
  }

  /// 잔액·정산 내역 등 실제 반영분만 (작년 채움·미래 제외).
  static List<TutorSettlementCalendarTransaction> realizedOnly(
    List<TutorSettlementCalendarTransaction> transactions,
    DateTime asOf,
  ) {
    final ref = _dateOnly(asOf);
    return transactions
        .where(
          (tx) =>
              !tx.filledFromPriorYear && !_dateOnly(tx.date).isAfter(ref),
        )
        .toList();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

