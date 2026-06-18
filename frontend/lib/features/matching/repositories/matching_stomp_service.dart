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
    void Function(String message)? onMatchCancelled,
    void Function(int problemId)? onNewProblem,
    List<int> matchingProblemIds = const [],
    void Function(int problemId)? onMatched,
  }) {
    _stomp = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        onConnect: (frame) {
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
                  onMatchCancelled?.call(json['message'] as String);
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
                  if (json['type'] == 'NEW_PROBLEM') {
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
                    onMatched?.call(pId);
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
