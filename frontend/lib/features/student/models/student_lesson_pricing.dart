import 'package:ieum/features/student/providers/student_wallet_provider.dart';

/// 문제 난이도별 1회 수업 예상 크레딧 (최대 5,000p).
/// 난이도는 추후 AI/백엔드에서 내려주며, 프론트는 값만 표시한다.
abstract final class StudentLessonPricing {
  static const maxPrice = 5000;

  static const easy = 'easy';
  static const medium = 'medium';
  static const hard = 'hard';

  static int priceForDifficulty(String difficulty) {
    return switch (difficulty) {
      easy => 3000,
      hard => 5000,
      _ => 4000,
    };
  }

  static String labelForDifficulty(String difficulty) {
    return switch (difficulty) {
      easy => '쉬움',
      hard => '어려움',
      _ => '보통',
    };
  }

  static String formattedPrice(int price) => '${formatCredits(price)}p';
}
