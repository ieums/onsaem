import 'package:flutter/material.dart';

/// 마이페이지 "온보딩 다시보기"로 진입할 때 라우트 extra 로 넘기는 인자.
///
/// 이 값이 있으면 = 다시보기 모드:
///  - [brightness] (현재 앱 테마)로 렌더(라이트 강제 안 함)
///  - 완료/건너뛰기 시 "봤음" 플래그를 바꾸지 않고 pop 으로 복귀
///
/// extra 가 없으면(첫 실행 게이팅) = 항상 라이트 + 플래그 저장 후 역할 홈으로.
@immutable
class OnboardingReviewArgs {
  const OnboardingReviewArgs({required this.brightness});

  final Brightness brightness;
}
