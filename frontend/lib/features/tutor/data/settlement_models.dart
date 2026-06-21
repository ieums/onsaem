// 백엔드 정산 도메인 응답 DTO.
// 정산 응답은 ApiResponse로 감싸지 않고 본문을 직접 내려주므로 res.data를 바로 파싱한다.

/// 정산 상태 (백엔드 SettlementStatus enum과 동일한 name 문자열).
enum SettlementStatus {
  calculated, // 정산 계산 완료 → 출금 요청 가능
  pending, // 송금 대기
  transferred, // 송금 완료
  failed, // 송금 실패
  unknown;

  static SettlementStatus fromName(String? name) {
    switch (name) {
      case 'CALCULATED':
        return SettlementStatus.calculated;
      case 'PENDING':
        return SettlementStatus.pending;
      case 'TRANSFERRED':
        return SettlementStatus.transferred;
      case 'FAILED':
        return SettlementStatus.failed;
      default:
        return SettlementStatus.unknown;
    }
  }
}

class SettlementResponse {
  const SettlementResponse({
    required this.id,
    required this.tutorId,
    required this.lessonId,
    required this.totalCoin,
    required this.platformFeeCoin,
    required this.tutorCoin,
    required this.tutorAmount,
    required this.status,
    required this.createdAt,
    this.transferredAt,
  });

  final int id;
  final int tutorId;
  final int lessonId;
  final int totalCoin;
  final int platformFeeCoin;
  final int tutorCoin;

  /// 강사 정산 금액(원).
  final int tutorAmount;
  final SettlementStatus status;
  final DateTime createdAt;

  /// 송금 완료 시점. TRANSFERRED 전에는 null.
  final DateTime? transferredAt;

  bool get isWithdrawable => status == SettlementStatus.calculated;

  factory SettlementResponse.fromJson(Map<String, dynamic> json) {
    return SettlementResponse(
      id: (json['id'] as num).toInt(),
      tutorId: (json['tutorId'] as num).toInt(),
      lessonId: (json['lessonId'] as num).toInt(),
      totalCoin: (json['totalCoin'] as num).toInt(),
      platformFeeCoin: (json['platformFeeCoin'] as num).toInt(),
      tutorCoin: (json['tutorCoin'] as num).toInt(),
      tutorAmount: (json['tutorAmount'] as num).toInt(),
      status: SettlementStatus.fromName(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      transferredAt: json['transferredAt'] == null
          ? null
          : DateTime.parse(json['transferredAt'] as String),
    );
  }
}

class SettlementSummaryResponse {
  const SettlementSummaryResponse({
    required this.tutorId,
    required this.totalAmount,
    required this.transferredAmount,
    required this.pendingAmount,
    required this.settlementCount,
  });

  final int tutorId;

  /// 누적 정산 총액(원).
  final int totalAmount;

  /// 송금 완료 누적액(원).
  final int transferredAmount;

  /// 송금 대기 + 계산 완료 누적액(원).
  final int pendingAmount;

  /// 정산 레코드 수.
  final int settlementCount;

  factory SettlementSummaryResponse.fromJson(Map<String, dynamic> json) {
    return SettlementSummaryResponse(
      tutorId: (json['tutorId'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toInt(),
      transferredAmount: (json['transferredAmount'] as num).toInt(),
      pendingAmount: (json['pendingAmount'] as num).toInt(),
      settlementCount: (json['settlementCount'] as num).toInt(),
    );
  }
}

class BulkWithdrawResponse {
  const BulkWithdrawResponse({
    required this.settlementCount,
    required this.totalAmount,
    required this.settlements,
  });

  final int settlementCount;
  final int totalAmount;
  final List<SettlementResponse> settlements;

  factory BulkWithdrawResponse.fromJson(Map<String, dynamic> json) {
    return BulkWithdrawResponse(
      settlementCount: (json['settlementCount'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toInt(),
      settlements: (json['settlements'] as List)
          .map((e) => SettlementResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// 달력·차트 표시용 거래 항목
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
  final bool filledFromPriorYear;

  bool get isDeposit => amount > 0;
}