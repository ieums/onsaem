import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 강사 온라인·수업 가능 상태 (홈 탭 ↔ 마이페이지 설정 공유)
final tutorAvailabilityProvider = StateProvider<bool>((ref) => true);
