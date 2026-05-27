/// 강사 문제·정산 공통 요금 규칙 (Flutter UI 의존 없음).
class TutorPricing {
  TutorPricing._();

  /// 문제(건)당 예상 금액 상한.
  static const maxPricePerProblemWon = 5000;

  /// [maxPricePerProblemWon]이 적용되는 기준 수업 시간(분).
  static const priceReferenceClassMinutes = 40;

  /// 예상 수업 시간에 비례해 산정, 문제당 최대 [maxPricePerProblemWon]원.
  static int expectedPriceWon(int classMinutes) {
    if (classMinutes <= 0) return 0;
    final scaled =
        (classMinutes * maxPricePerProblemWon / priceReferenceClassMinutes)
            .round();
    return scaled.clamp(0, maxPricePerProblemWon);
  }
}
