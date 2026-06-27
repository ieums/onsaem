import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/api_constants.dart';

class StudentMatchingStompService {
  StompClient? _stomp;

  void connect(
    int studentId,
    int problemId, {
    void Function(int problemId)? onTutorApplied,
    void Function(int tutorId)? onTutorCancelled,
    void Function(int problemId, int tutorId, String message)? onMatchRequested,
    void Function(String message)? onMatchCancelled,
    void Function()? onSearchExpiringSoon,
    void Function()? onSearchExpired,
    void Function(String channelName, List<String> imageUrls, String? subject, String? tutorProfileImageUrl, String? studentProfileImageUrl)? onMatched,
    void Function(int tutorId)? onTutorUnavailable,
    void Function(int tutorId)? onTutorAvailable,
  }) {
    _stomp = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        onConnect: (frame) {
          _stomp!.subscribe(
            destination: '/topic/student/$studentId',
            callback: (frame) {
              if (frame.body == null) return;
              try {
                final json =
                    jsonDecode(frame.body!) as Map<String, dynamic>;
                final type = json['type'] as String?;
                switch (type) {
                  case 'TUTOR_APPLIED':
                    onTutorApplied?.call(json['problemId'] as int);
                  case 'TUTOR_CANCELLED':
                    onTutorCancelled?.call(json['tutorId'] as int);
                  case 'MATCH_REQUESTED':
                    onMatchRequested?.call(
                      json['problemId'] as int,
                      json['tutorId'] as int,
                      json['message'] as String? ?? '',
                    );
                  case 'MATCH_CANCELLED':
                    onMatchCancelled?.call(json['message'] as String? ?? '');
                  case 'SEARCH_EXPIRING_SOON':
                    onSearchExpiringSoon?.call();
                  case 'SEARCH_EXPIRED':
                    onSearchExpired?.call();
                }
              } catch (_) {}
            },
          );

          _stomp!.subscribe(
            destination: '/topic/matching/$problemId',
            callback: (frame) {
              if (frame.body == null) return;
              try {
                final json =
                    jsonDecode(frame.body!) as Map<String, dynamic>;
                final type = json['type'] as String?;
                switch (type) {
                  case 'MATCHED':
                    final channelName = json['channelName'] as String? ?? '';
                    final imageUrls =
                        (json['imageUrls'] as List<dynamic>? ?? [])
                            .cast<String>();
                    final subject = json['subject'] as String?;
                    final tutorProfileImageUrl = json['tutorProfileImageUrl'] as String?;
                    final studentProfileImageUrl = json['studentProfileImageUrl'] as String?;
                    onMatched?.call(channelName, imageUrls, subject, tutorProfileImageUrl, studentProfileImageUrl);
                  case 'TUTOR_UNAVAILABLE':
                    onTutorUnavailable?.call(json['tutorId'] as int);
                  case 'TUTOR_AVAILABLE':
                    onTutorAvailable?.call(json['tutorId'] as int);
                }
              } catch (_) {}
            },
          );
        },
        reconnectDelay: const Duration(seconds: 3),
        onWebSocketError: (e) =>
            debugPrint('[STOMP:StudentMatching] WebSocket error: $e'),
        onStompError: (f) =>
            debugPrint('[STOMP:StudentMatching] STOMP error: ${f.body}'),
      ),
    );
    _stomp!.activate();
  }

  void disconnect() {
    _stomp?.deactivate();
    _stomp = null;
  }
}
