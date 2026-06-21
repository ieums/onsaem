import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/providers/app_lifecycle_provider.dart';
import 'package:ieum/features/student/models/student_home_notification.dart';
import 'package:ieum/features/student/models/student_notification_category.dart';
import 'package:ieum/features/student/providers/student_shell_tab_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsMatchingKey = 'student_notif_matching';
const _prefsAiTutorKey = 'student_notif_ai_tutor';
const _prefsExtendTimeKey = 'student_notif_extend_time';
const _inboxPrefsKey = 'student_notif_inbox_v1';
const _maxInboxItems = 20;
const _readRetentionDays = 1;
const _unreadRetentionDays = 3;

class StudentNotificationSettings {
  const StudentNotificationSettings({
    required this.matching,
    required this.aiTutor,
    required this.extendTime,
  });

  final bool matching;
  final bool aiTutor;
  final bool extendTime;

  StudentNotificationSettings copyWith({
    bool? matching,
    bool? aiTutor,
    bool? extendTime,
  }) {
    return StudentNotificationSettings(
      matching: matching ?? this.matching,
      aiTutor: aiTutor ?? this.aiTutor,
      extendTime: extendTime ?? this.extendTime,
    );
  }

  bool isEnabled(StudentNotificationCategory category) {
    return switch (category) {
      StudentNotificationCategory.matching => matching,
      StudentNotificationCategory.aiTutor => aiTutor,
      StudentNotificationCategory.extendTime => extendTime,
    };
  }
}

class StudentNotificationSettingsNotifier
    extends StateNotifier<StudentNotificationSettings> {
  StudentNotificationSettingsNotifier()
      : super(
          const StudentNotificationSettings(
            matching: true,
            aiTutor: true,
            extendTime: true,
          ),
        ) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = StudentNotificationSettings(
      matching: _prefs!.getBool(_prefsMatchingKey) ?? true,
      aiTutor: _prefs!.getBool(_prefsAiTutorKey) ?? true,
      extendTime: _prefs!.getBool(_prefsExtendTimeKey) ?? true,
    );
  }

  Future<void> setMatching(bool value) async {
    state = state.copyWith(matching: value);
    await _prefs?.setBool(_prefsMatchingKey, value);
  }

  Future<void> setAiTutor(bool value) async {
    state = state.copyWith(aiTutor: value);
    await _prefs?.setBool(_prefsAiTutorKey, value);
  }

  Future<void> setExtendTime(bool value) async {
    state = state.copyWith(extendTime: value);
    await _prefs?.setBool(_prefsExtendTimeKey, value);
  }
}

final studentNotificationSettingsProvider = StateNotifierProvider<
    StudentNotificationSettingsNotifier, StudentNotificationSettings>(
  (ref) => StudentNotificationSettingsNotifier(),
);

class StudentNotificationInboxNotifier
    extends StateNotifier<List<StudentHomeNotification>> {
  StudentNotificationInboxNotifier() : super(const []) {
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
          .map(
            (entry) => StudentHomeNotification.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
      state = _applyRetention(items);
      await _persist();
    } catch (error, stackTrace) {
      debugPrint('[Onsaem] 알림 인박스 로드 실패: $error');
      debugPrint('$stackTrace');
    }
  }

  List<StudentHomeNotification> _applyRetention(
    List<StudentHomeNotification> items,
  ) {
    final now = DateTime.now();
    final pruned = items.where((item) {
      final age = now.difference(item.createdAt).inDays;
      if (item.isRead) return age <= _readRetentionDays;
      return age <= _unreadRetentionDays;
    }).toList();

    if (pruned.length <= _maxInboxItems) return pruned;
    return pruned.sublist(0, _maxInboxItems);
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((item) => item.toJson()).toList());
    await _prefs!.setString(_inboxPrefsKey, encoded);
  }

  bool _containsDedupeKey(String dedupeKey) {
    return state.any((item) => item.dedupeKey == dedupeKey);
  }

  void prependIfNew(StudentHomeNotification item) {
    if (_containsDedupeKey(item.dedupeKey)) return;
    state = _applyRetention([item, ...state]);
    _persist();
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    state = [...state]..removeAt(index);
    _persist();
  }

  void markAllRead() {
    if (state.every((item) => item.isRead)) return;
    state = [
      for (final item in state) item.copyWith(isRead: true),
    ];
    _persist();
  }
}

final studentNotificationInboxProvider = StateNotifierProvider<
    StudentNotificationInboxNotifier, List<StudentHomeNotification>>(
  (ref) => StudentNotificationInboxNotifier(),
);

final studentNotificationControllerProvider =
    Provider<StudentNotificationController>(
  (ref) => StudentNotificationController(ref),
);

class StudentNotificationController {
  StudentNotificationController(this._ref);

  final Ref _ref;

  AppNotificationService get _service => _ref.read(appNotificationServiceProvider);

  bool _isEnabled(StudentNotificationCategory category) {
    return _ref.read(studentNotificationSettingsProvider).isEnabled(category);
  }

  void _prependInbox({
    required String dedupeKey,
    required StudentNotificationCategory category,
    required String title,
    required String body,
  }) {
    _ref.read(studentNotificationInboxProvider.notifier).prependIfNew(
          StudentHomeNotification(
            id: 'inbox-$dedupeKey',
            dedupeKey: dedupeKey,
            title: title,
            body: body,
            createdAt: DateTime.now(),
            isRead: false,
            category: category,
          ),
        );
  }

  bool _isAiTutorTabInForeground() {
    final tabIndex = _ref.read(studentShellTabIndexProvider);
    final lifecycle = _ref.read(appLifecycleProvider);
    return tabIndex == studentShellAiTutorTabIndex &&
        lifecycle == AppLifecycleState.resumed;
  }

  void deliverMatchingComplete({
    required String dedupeKey,
    required String tutorName,
    required String subject,
  }) {
    if (!_isEnabled(StudentNotificationCategory.matching)) return;

    const sessionMinutes = 30;
    final title = '$tutorName님과 과외가 연결됐어요';
    final body = '$subject 수업이 시작됐습니다. 기본 수업 시간은 $sessionMinutes분이에요.';

    _prependInbox(
      dedupeKey: dedupeKey,
      category: StudentNotificationCategory.matching,
      title: title,
      body: body,
    );
  }

  Future<void> deliverSubjectExpertAssigned({
    required String dedupeKey,
    required String subject,
  }) async {
    if (!_isEnabled(StudentNotificationCategory.matching)) return;

    const title = '담당 과목 강사님이 배치됐어요!';
    final body = '$subject 담당 강사를 확인하고 선택해 주세요.';

    _prependInbox(
      dedupeKey: dedupeKey,
      category: StudentNotificationCategory.matching,
      title: title,
      body: body,
    );

    await _service.showBanner(
      dedupeKey: dedupeKey,
      title: title,
      body: body,
    );
  }

  Future<bool> scheduleSessionExtension({
    required String dedupeKey,
    required String tutorName,
    required String subject,
    required Duration delay,
  }) async {
    if (!_isEnabled(StudentNotificationCategory.extendTime)) return false;

    const extendMinutes = 30;
    final title = '수업 종료 5분 전이에요';
    final body =
        '$tutorName 강사와의 $subject 수업을 $extendMinutes분 연장할 수 있어요.';

    return _service.scheduleBanner(
      dedupeKey: dedupeKey,
      title: title,
      body: body,
      delay: delay,
    );
  }

  void deliverSessionExtension({
    required String dedupeKey,
    required String tutorName,
    required String subject,
  }) {
    if (!_isEnabled(StudentNotificationCategory.extendTime)) return;

    const extendMinutes = 30;
    final title = '수업 종료 5분 전이에요';
    final body =
        '$tutorName 강사와의 $subject 수업을 $extendMinutes분 연장할 수 있어요.';

    _prependInbox(
      dedupeKey: dedupeKey,
      category: StudentNotificationCategory.extendTime,
      title: title,
      body: body,
    );
  }

  Future<void> scheduleAiTutorResponse({
    required String dedupeKey,
    required String preview,
    required Duration delay,
  }) async {
    if (!_isEnabled(StudentNotificationCategory.aiTutor)) return;

    if (_isAiTutorTabInForeground()) {
      return;
    }

    await _service.scheduleBanner(
      dedupeKey: dedupeKey,
      title: 'AI 튜터 답변',
      body: preview,
      delay: delay,
    );
  }

  Future<void> cancelScheduledKeys(List<String> dedupeKeys) async {
    for (final key in dedupeKeys) {
      await _service.cancelScheduled(key);
    }
  }

  Future<void> onAiTutorResponseArrived({
    required String dedupeKey,
    required String preview,
  }) async {
    if (!_isEnabled(StudentNotificationCategory.aiTutor)) return;

    _prependInbox(
      dedupeKey: dedupeKey,
      category: StudentNotificationCategory.aiTutor,
      title: 'AI 튜터 답변',
      body: preview,
    );

    if (_isAiTutorTabInForeground()) {
      await _service.cancelScheduled(dedupeKey);
      await _service.playInAppAlertSound();
      return;
    }

    final lifecycle = _ref.read(appLifecycleProvider);
    if (lifecycle != AppLifecycleState.resumed) {
      return;
    }

    await _service.cancelScheduled(dedupeKey);
    await _service.showBanner(
      dedupeKey: dedupeKey,
      title: 'AI 튜터 답변',
      body: preview,
    );
  }
}
