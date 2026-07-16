// 백엔드 정산 도메인 응답 DTO.
// 정산 응답은 ApiResponse로 감싸지 않고 본문을 직접 내려주므로 res.data를 바로 파싱한다.

/// 정산 상태 (백엔드 SettlementStatus enum과 동일한 name 문자열).
enum SettlementStatus {
  calculated, // 정산 계산 완료 → 출금 요청 가능
  pending, // 송금 대기
  transferred, // 송금 완료
  failed, // 송금 실패
  canceled, // 정산 취소(환불 등) — 수입 집계에서 제외
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
      case 'CANCELED':
        return SettlementStatus.canceled;
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
    this.subject,
    this.lessonDate,
    required this.createdAt,
    this.transferredAt,
    this.reportPending = false,
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

  /// 표시용 과목(한글, 예: "수학"). 없을 수 있음.
  final String? subject;

  /// 실제 수업 날짜(강의 종료 시각). 없을 수 있음.
  final DateTime? lessonDate;

  final DateTime createdAt;

  /// 송금 완료 시점. TRANSFERRED 전에는 null.
  final DateTime? transferredAt;

  /// 그 강의에 처리 중인 신고가 있어 출금이 보류된 상태.
  final bool reportPending;

  /// 출금 가능: 계산 완료 + 신고 보류 아님.
  bool get isWithdrawable =>
      status == SettlementStatus.calculated && !reportPending;

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
      subject: json['subject'] as String?,
      lessonDate: json['lessonDate'] == null
          ? null
          : DateTime.parse(json['lessonDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      transferredAt: json['transferredAt'] == null
          ? null
          : DateTime.parse(json['transferredAt'] as String),
      reportPending: json['reportPending'] as bool? ?? false,
    );
  }
}

/// 정산 예정 보류 사유 (백엔드 PendingSettlementReason enum과 동일).
enum PendingSettlementReason {
  waitingPeriod, // 수업 종료 후 24시간 정산 대기
  reportHold, // 신고 처리 중 보류
  processing, // 곧 자동 정산될 예정
  unknown;

  static PendingSettlementReason fromName(String? name) {
    switch (name) {
      case 'WAITING_PERIOD':
        return PendingSettlementReason.waitingPeriod;
      case 'REPORT_HOLD':
        return PendingSettlementReason.reportHold;
      case 'PROCESSING':
        return PendingSettlementReason.processing;
      default:
        return PendingSettlementReason.unknown;
    }
  }
}

/// 완료됐지만 아직 정산되지 않은 강의(정산 예정).
class PendingSettlementResponse {
  const PendingSettlementResponse({
    required this.lessonId,
    required this.totalCoin,
    required this.expectedTutorAmount,
    this.subject,
    this.lessonDate,
    required this.reason,
  });

  final int lessonId;
  final int totalCoin;

  /// 정산되면 받게 될 예상 강사 정산금(원).
  final int expectedTutorAmount;
  final String? subject;
  final DateTime? lessonDate;
  final PendingSettlementReason reason;

  factory PendingSettlementResponse.fromJson(Map<String, dynamic> json) {
    return PendingSettlementResponse(
      lessonId: (json['lessonId'] as num).toInt(),
      totalCoin: (json['totalCoin'] as num).toInt(),
      expectedTutorAmount: (json['expectedTutorAmount'] as num).toInt(),
      subject: json['subject'] as String?,
      lessonDate: json['lessonDate'] == null
          ? null
          : DateTime.parse(json['lessonDate'] as String),
      reason: PendingSettlementReason.fromName(json['reason'] as String?),
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
    this.subject,
    this.filledFromPriorYear = false,
  });

  final DateTime date;
  final String label;
  final int amount;

  /// 입금(수업 완료) 거래의 과목명(예: "수학"). 출금 거래는 null.
  final String? subject;
  final bool filledFromPriorYear;

  bool get isDeposit => amount > 0;
}

/// 강사 정산 입금 계좌. 미등록 시 필드가 null.
class SettlementAccount {
  const SettlementAccount({this.bank, this.account, this.holder});

  final String? bank;
  final String? account;
  final String? holder;

  factory SettlementAccount.fromJson(Map<String, dynamic> json) {
    return SettlementAccount(
      bank: json['bank'] as String?,
      account: json['account'] as String?,
      holder: json['holder'] as String?,
    );
  }
}