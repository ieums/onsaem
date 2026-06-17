import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/api_constants.dart';

class MatchingStompService {
  StompClient? _stomp;

  void connect(int tutorId, void Function(int problemId) onProblemMatched) {
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
                if (json['type'] == 'PROBLEM_MATCHED') {
                  onProblemMatched(json['problemId'] as int);
                }
              } catch (_) {}
            },
          );
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
