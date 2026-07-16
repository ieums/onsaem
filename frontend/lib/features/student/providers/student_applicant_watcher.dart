import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// 홈/목록의 '지원 강사 N명'을 항상 실시간으로 유지하기 위한 상시 워처.
///
/// 매칭 세션과 무관하게 `/topic/student/{id}`를 구독해, 어떤 문제든 강사가
/// 신청·취소하면 [studentProblemsProvider]를 무효화한다. (세션이 없어도 동작)
/// 학생 셸에서 watch해 로그인 동안 살아있게 한다.
final studentApplicantWatcherProvider = Provider.autoDispose<void>((ref) {
  final studentId = ref.watch(currentUserProvider)?.id;
  if (studentId == null) return;

  late final StompClient client;
  client = StompClient(
    config: StompConfig(
      url: ApiConstants.wsUrl,
      onConnect: (_) {
        client.subscribe(
          destination: '/topic/student/$studentId',
          callback: (frame) {
            if (frame.body == null) return;
            try {
              final json = jsonDecode(frame.body!) as Map<String, dynamic>;
              final type = json['type'] as String?;
              if (type == 'TUTOR_APPLIED' || type == 'TUTOR_CANCELLED') {
                // 지원 강사 수가 바뀌었으니 홈/목록 새로고침.
                ref.invalidate(studentProblemsProvider);
              }
            } catch (_) {}
          },
        );
      },
      reconnectDelay: const Duration(seconds: 3),
      onWebSocketError: (e) =>
          debugPrint('[STOMP:ApplicantWatcher] WebSocket error: $e'),
      onStompError: (f) =>
          debugPrint('[STOMP:ApplicantWatcher] STOMP error: ${f.body}'),
    ),
  );
  client.activate();
  ref.onDispose(() => client.deactivate());
});
