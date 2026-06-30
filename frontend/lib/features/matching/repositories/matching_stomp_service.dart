import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/api_constants.dart';

class MatchingStompService {
  StompClient? _stomp;

  void connect(
    int tutorId,
    void Function(int problemId) onProblemMatched, {
    void Function(int problemId, int tutorId, String message)? onMatchRequested,
    void Function(int problemId, String message)? onMatchCancelled,
    void Function(int problemId)? onNewProblem,
    void Function(String type, String message)? onVerification,
    List<int> matchingProblemIds = const [],
    void Function(int problemId, String channelName, List<String> imageUrls, String? subject, String? tutorProfileImageUrl, String? studentProfileImageUrl)? onMatched,
  }) {
    _stomp = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        onConnect: (frame) {
          debugPrint(
              '[STOMP:Matching] 연결됨 → ${ApiConstants.wsUrl} (tutorId=$tutorId) 구독 시작');
          _stomp!.subscribe(
            destination: '/topic/tutor/$tutorId',
            callback: (frame) {
              if (frame.body == null) return;
              try {
                final json =
                    jsonDecode(frame.body!) as Map<String, dynamic>;
                final type = json['type'] as String?;
                if (type == 'PROBLEM_MATCHED') {
                  onProblemMatched(json['problemId'] as int);
                } else if (type == 'MATCH_REQUESTED') {
                  onMatchRequested?.call(
                    json['problemId'] as int,
                    json['tutorId'] as int,
                    json['message'] as String,
                  );
                } else if (type == 'MATCH_CANCELLED') {
                  onMatchCancelled?.call(
                    json['problemId'] as int,
                    json['message'] as String? ?? '',
                  );
                } else if (type == 'VERIFICATION_APPROVED' ||
                    type == 'VERIFICATION_REJECTED') {
                  onVerification?.call(
                    type!,
                    json['message'] as String? ?? '',
                  );
                }
              } catch (_) {}
            },
          );

          if (onNewProblem != null) {
            _stomp!.subscribe(
              destination: '/topic/new-problem',
              callback: (frame) {
                if (frame.body == null) return;
                try {
                  final json =
                      jsonDecode(frame.body!) as Map<String, dynamic>;
                  debugPrint('[STOMP:Matching] /topic/new-problem 수신: ${frame.body}');
                  // NEW_PROBLEM(새 문제) / PROBLEM_REMOVED(취소·종료) 둘 다 리스트 재조회로 반영.
                  // (재조회 시 searching=true 조건이라 취소된 문제는 자동 제외됨)
                  final type = json['type'];
                  if (type == 'NEW_PROBLEM' || type == 'PROBLEM_REMOVED') {
                    onNewProblem(json['problemId'] as int);
                  }
                } catch (_) {}
              },
            );
          }

          for (final pId in matchingProblemIds) {
            _stomp!.subscribe(
              destination: '/topic/matching/$pId',
              callback: (frame) {
                if (frame.body == null) return;
                try {
                  final json =
                      jsonDecode(frame.body!) as Map<String, dynamic>;
                  if (json['type'] == 'MATCHED') {
                    final matchedTutorId = json['tutorId'] as int?;
                    if (matchedTutorId != tutorId) return;
                    final channelName = json['channelName'] as String? ?? '';
                    final imageUrls =
                        (json['imageUrls'] as List<dynamic>? ?? []).cast<String>();
                    final subject = json['subject'] as String?;
                    final tutorProfileImageUrl = json['tutorProfileImageUrl'] as String?;
                    final studentProfileImageUrl = json['studentProfileImageUrl'] as String?;
                    onMatched?.call(pId, channelName, imageUrls, subject, tutorProfileImageUrl, studentProfileImageUrl);
                  }
                } catch (_) {}
              },
            );
          }
        },
        reconnectDelay: const Duration(seconds: 3),
        onWebSocketError: (e) =>
            debugPrint('[STOMP:Matching] WebSocket error: $e'),
        onStompError: (f) =>
            debugPrint('[STOMP:Matching] STOMP error: ${f.body}'),
      ),
    );
    _stomp!.activate();
  }

  void disconnect() {
    _stomp?.deactivate();
    _stomp = null;
  }
}
