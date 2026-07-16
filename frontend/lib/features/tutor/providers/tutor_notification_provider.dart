import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/notification_center.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _inboxPrefsKey = 'tutor_notif_inbox_v1';
const _pushPrefsKey = 'tutor_notif_push';
const _maxInboxItems = 20;
const _readRetentionDays = 1;
const _unreadRetentionDays = 3;

/// 강사 "푸시 알림 받기" 앱 레벨 on/off pref(영속). 학생 패턴과 동일하게
/// OS 권한과 별개로 앱에서 끌 수 있게 한다. (기본 on)
class TutorPushSettingsNotifier extends StateNotifier<bool> {
  TutorPushSettingsNotifier() : super(true) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs!.getBool(_pushPrefsKey) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    await _prefs?.setBool(_pushPrefsKey, value);
  }
}

final tutorPushEnabledProvider =
    StateNotifierProvider<TutorPushSettingsNotifier, bool>(
  (ref) => TutorPushSettingsNotifier(),
);

/// 강사 알림 1건. (학생 인박스와 동일 구조 + 종류(kind) 직접 보관)
class TutorNotification {
  const TutorNotification({
    required this.id,
    required this.dedupeKey,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.kind,
  });

  final String id;
  final String dedupeKey;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationKind kind;

  TutorNotification copyWith({bool? isRead}) => TutorNotification(
        id: id,
        dedupeKey: dedupeKey,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        kind: kind,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dedupeKey': dedupeKey,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'kind': kind.name,
      };

  factory TutorNotification.fromJson(Map<String, dynamic> j) =>
      TutorNotification(
        id: j['id'] as String,
        dedupeKey: j['dedupeKey'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isRead: j['isRead'] as bool? ?? false,
        kind: NotificationKind.values
            .firstWhere((k) => k.name == j['kind'], orElse: () => NotificationKind.general),
      );
}

class TutorNotificationInboxNotifier
    extends StateNotifier<List<TutorNotification>> {
  TutorNotificationInboxNotifier() : super(const []) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_inboxPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .map((e) => TutorNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = _applyRetention(items);
      await _persist();
    } catch (error) {
      debugPrint('[Onsaem] 강사 알림 인박스 로드 실패: $error');
    }
  }

  List<TutorNotification> _applyRetention(List<TutorNotification> items) {
    final now = DateTime.now();
    final pruned = items.where((item) {
      final age = now.difference(item.createdAt).inDays;
      return item.isRead ? age <= _readRetentionDays : age <= _unreadRetentionDays;
    }).toList();
    return pruned.length <= _maxInboxItems ? pruned : pruned.sublist(0, _maxInboxItems);
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
        _inboxPrefsKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  /// 같은 dedupeKey가 이미 있으면 무시(중복 방지).
  void add({
    required String dedupeKey,
    required String title,
    required String body,
    required NotificationKind kind,
  }) {
    if (state.any((e) => e.dedupeKey == dedupeKey)) return;
    final item = TutorNotification(
      id: 'inbox-$dedupeKey',
      dedupeKey: dedupeKey,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
      kind: kind,
    );
    state = _applyRetention([item, ...state]);
    _persist();
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    state = [...state]..removeAt(index);
    _persist();
  }

  void markAllRead() {
    if (state.every((e) => e.isRead)) return;
    state = [for (final e in state) e.copyWith(isRead: true)];
    _persist();
  }
}

final tutorNotificationInboxProvider = StateNotifierProvider<
    TutorNotificationInboxNotifier, List<TutorNotification>>(
  (ref) => TutorNotificationInboxNotifier(),
);

/// 미읽음 개수(종 아이콘 배지용).
final tutorUnreadCountProvider = Provider<int>((ref) =>
    ref.watch(tutorNotificationInboxProvider).where((e) => !e.isRead).length);
