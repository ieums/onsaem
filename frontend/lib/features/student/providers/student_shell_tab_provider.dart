import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 학생 셸 하단 탭 인덱스 (0: 홈 · 1: 복습 · 2: AI튜터 · 3: 마이)
final studentShellTabIndexProvider = StateProvider<int>((ref) => 0);

const studentShellAiTutorTabIndex = 2;
