import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AutoPayMethod { card }

extension AutoPayMethodX on AutoPayMethod {
  String get label => '신용·체크카드';

  IconData get icon => Icons.credit_card_rounded;

  Color get badgeColor => const Color(0xFF5B9BD5);
}

class CreditHistoryEntry {
  const CreditHistoryEntry({
    required this.date,
    required this.pointDelta,
    required this.title,
  });

  final String date;
  final int pointDelta;
  final String title;
}

class RechargePackage {
  const RechargePackage({
    required this.price,
    required this.points,
    this.bonusPoints = 0,
    this.isBest = false,
  });

  final int price;
  final int points;
  final int bonusPoints;
  final bool isBest;

  int get totalPoints => points + bonusPoints;
}

class StudentWalletState {
  const StudentWalletState({
    this.balance = 12500,
    this.autoPayMethod = AutoPayMethod.card,
    this.cardCompany = '신한카드',
    this.cardNumber = '1234-5678-9012-3456',
    this.cardExpiry = '12/28',
    this.cardHolder = '테스트',
    this.history = const [
      CreditHistoryEntry(
        date: '2026.05.20',
        pointDelta: -3000,
        title: '수학 과외 결제',
      ),
      CreditHistoryEntry(
        date: '2026.05.18',
        pointDelta: 5500,
        title: '크레딧 충전',
      ),
      CreditHistoryEntry(
        date: '2026.05.10',
        pointDelta: 3000,
        title: '크레딧 충전',
      ),
      CreditHistoryEntry(
        date: '2026.05.05',
        pointDelta: -1500,
        title: '영어 과외 결제',
      ),
      CreditHistoryEntry(
        date: '2026.05.02',
        pointDelta: 11000,
        title: '크레딧 충전 · 신용·체크카드',
      ),
      CreditHistoryEntry(
        date: '2026.04.28',
        pointDelta: -2000,
        title: '과학 과외 결제',
      ),
      CreditHistoryEntry(
        date: '2026.04.20',
        pointDelta: 3000,
        title: '크레딧 충전',
      ),
    ],
  });

  final int balance;
  final AutoPayMethod autoPayMethod;
  final String cardCompany;
  final String cardNumber;
  final String cardExpiry;
  final String cardHolder;
  final List<CreditHistoryEntry> history;

  String get maskedCardNumber {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return cardNumber;
    final last4 = digits.substring(digits.length - 4);
    return '$cardCompany · **** $last4';
  }

  StudentWalletState copyWith({
    int? balance,
    AutoPayMethod? autoPayMethod,
    String? cardCompany,
    String? cardNumber,
    String? cardExpiry,
    String? cardHolder,
    List<CreditHistoryEntry>? history,
  }) {
    return StudentWalletState(
      balance: balance ?? this.balance,
      autoPayMethod: autoPayMethod ?? this.autoPayMethod,
      cardCompany: cardCompany ?? this.cardCompany,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cardHolder: cardHolder ?? this.cardHolder,
      history: history ?? this.history,
    );
  }
}

class StudentWalletNotifier extends StateNotifier<StudentWalletState> {
  StudentWalletNotifier() : super(const StudentWalletState());

  static const rechargePackages = [
    RechargePackage(price: 3000, points: 3000),
    RechargePackage(price: 5000, points: 5000, bonusPoints: 500, isBest: true),
    RechargePackage(price: 10000, points: 10000, bonusPoints: 1000),
  ];

  void updatePaymentMethod({
    required String cardCompany,
    required String cardNumber,
    required String cardExpiry,
    required String cardHolder,
  }) {
    state = state.copyWith(
      cardCompany: cardCompany,
      cardNumber: cardNumber,
      cardExpiry: cardExpiry,
      cardHolder: cardHolder,
      autoPayMethod: AutoPayMethod.card,
    );
  }

  void recharge(RechargePackage package) {
    final today = _todayLabel();
    state = state.copyWith(
      balance: state.balance + package.totalPoints,
      history: [
        CreditHistoryEntry(
          date: today,
          pointDelta: package.totalPoints,
          title: '크레딧 충전 · ${AutoPayMethod.card.label}',
        ),
        ...state.history,
      ],
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}.$m.$d';
  }
}

final studentWalletProvider =
    StateNotifierProvider<StudentWalletNotifier, StudentWalletState>(
  (ref) => StudentWalletNotifier(),
);

String formatCredits(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
