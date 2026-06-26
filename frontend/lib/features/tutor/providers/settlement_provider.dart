import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/tutor/data/settlement_models.dart';
import 'package:ieum/features/tutor/data/settlement_repository.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>(
  (ref) => SettlementRepository(),
);

/// 정산 화면이 한 번에 쓰는 데이터 묶음.
class TutorSettlementData {
  const TutorSettlementData({
    required this.summary,
    required this.records,
    required this.transactions,
  });

  final SettlementSummaryResponse summary;

  /// 정산 건(수업 단위) 목록 — 상태 뱃지·출금 요청에 사용.
  final List<SettlementResponse> records;

  /// 달력·차트가 쓰는 부호 있는 거래 목록(입금 +, 송금완료 출금 -).
  final List<TutorSettlementCalendarTransaction> transactions;
}

/// 정산 레코드 → 달력/차트용 거래 목록 변환.
/// - 정산 발생: 입금(+tutorAmount, createdAt)
/// - 송금 완료: 출금(-tutorAmount, transferredAt)
List<TutorSettlementCalendarTransaction> settlementRecordsToTransactions(
  List<SettlementResponse> records,
) {
  final out = <TutorSettlementCalendarTransaction>[];
  for (final r in records) {
    out.add(
      TutorSettlementCalendarTransaction(
        date: r.createdAt,
        label: '입금',
        amount: r.tutorAmount,
      ),
    );
    if (r.status == SettlementStatus.transferred && r.transferredAt != null) {
      out.add(
        TutorSettlementCalendarTransaction(
          date: r.transferredAt!,
          label: '출금',
          amount: -r.tutorAmount,
        ),
      );
    }
  }
  return out;
}

final settlementDataProvider =
    FutureProvider.autoDispose<TutorSettlementData>((ref) async {
  final tutorId = ref.watch(currentUserProvider)?.id;
  if (tutorId == null) {
    throw StateError('로그인이 필요합니다.');
  }
  final repo = ref.watch(settlementRepositoryProvider);
  final records = await repo.fetchByTutor(tutorId);
  final summary = await repo.fetchSummary(tutorId);
  return TutorSettlementData(
    summary: summary,
    records: records,
    transactions: settlementRecordsToTransactions(records),
  );
});
