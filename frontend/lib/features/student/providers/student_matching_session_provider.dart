import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/features/student/data/student_home_dummy_data.dart';
import 'package:ieum/features/student/data/student_tutor_dummy_data.dart';
import 'package:ieum/features/student/models/student_lesson_session_config.dart';
import 'package:ieum/features/student/models/student_lesson_pricing.dart';
import 'package:ieum/features/student/models/student_tutor_profile.dart';
import 'package:ieum/features/student/providers/student_notification_provider.dart';

enum StudentMatchingSessionStatus {
  matching,
  selectingTutor,
  connecting,
  connected,
}

class StudentMatchingSession {
  const StudentMatchingSession({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.status,
    required this.startedAt,
    required this.matchDedupeKey,
    required this.extendDedupeKey,
    required this.candidateIds,
    required this.questionSummary,
    this.problemImageBytes,
    this.selectedTutorId,
    this.waitingForSubjectExpert = false,
    this.hasWaitedForSubjectExpert = false,
  });

  final String id;
  final String subject;
  final String difficulty;
  final StudentMatchingSessionStatus status;
  final DateTime startedAt;
  final String matchDedupeKey;
  final String extendDedupeKey;
  final List<String> candidateIds;
  final String questionSummary;
  final Uint8List? problemImageBytes;
  final String? selectedTutorId;
  final bool waitingForSubjectExpert;
  final bool hasWaitedForSubjectExpert;

  int get lessonPrice => StudentLessonPricing.priceForDifficulty(difficulty);

  StudentTutorProfile? get selectedTutor =>
      selectedTutorId == null ? null : StudentTutorDummyData.byId(selectedTutorId!);

  List<StudentTutorProfile> get candidates => candidateIds
      .map(StudentTutorDummyData.byId)
      .whereType<StudentTutorProfile>()
      .toList();

  bool get hasSubjectExpert =>
      candidates.any((tutor) => tutor.subjects.contains(subject));

  bool get isNonSubjectOnlyMatch =>
      candidates.isNotEmpty && !hasSubjectExpert;

  bool get showOnHomePending =>
      waitingForSubjectExpert ||
      status == StudentMatchingSessionStatus.selectingTutor ||
      status == StudentMatchingSessionStatus.connecting ||
      status == StudentMatchingSessionStatus.connected;

  StudentMatchingSession copyWith({
    String? id,
    String? subject,
    String? difficulty,
    StudentMatchingSessionStatus? status,
    DateTime? startedAt,
    String? matchDedupeKey,
    String? extendDedupeKey,
    List<String>? candidateIds,
    String? questionSummary,
    Uint8List? problemImageBytes,
    String? selectedTutorId,
    bool clearSelectedTutorId = false,
    bool? waitingForSubjectExpert,
    bool? hasWaitedForSubjectExpert,
  }) {
    return StudentMatchingSession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      matchDedupeKey: matchDedupeKey ?? this.matchDedupeKey,
      extendDedupeKey: extendDedupeKey ?? this.extendDedupeKey,
      candidateIds: candidateIds ?? this.candidateIds,
      questionSummary: questionSummary ?? this.questionSummary,
      problemImageBytes: problemImageBytes ?? this.problemImageBytes,
      selectedTutorId:
          clearSelectedTutorId ? null : (selectedTutorId ?? this.selectedTutorId),
      waitingForSubjectExpert:
          waitingForSubjectExpert ?? this.waitingForSubjectExpert,
      hasWaitedForSubjectExpert:
          hasWaitedForSubjectExpert ?? this.hasWaitedForSubjectExpert,
    );
  }
}

class StudentMatchingSessionNotifier extends StateNotifier<StudentMatchingSession?> {
  StudentMatchingSessionNotifier(this._ref) : super(null);

  final Ref _ref;
  Timer? _matchStateTimer;
  Timer? _subjectExpertWaitTimer;
  Timer? _connectionTimer;
  Timer? _extensionTimer;

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  Future<bool> startMatchingFromPending() async {
    if (state?.status == StudentMatchingSessionStatus.matching) return true;

    final pending = StudentHomeDummyData.pendingQuestions;
    final target = pending.isNotEmpty ? pending.first : null;
    final sessionToken = DateTime.now().millisecondsSinceEpoch;

    return startMatching(
      subject: target?.subject ?? '수학',
      questionSummary: '매칭 대기 중인 질문',
      pendingId: target?.id ?? 'demo-match',
      sessionToken: sessionToken,
    );
  }

  Future<bool> startMatching({
    required String subject,
    required String pendingId,
    required int sessionToken,
    required String questionSummary,
    Uint8List? problemImageBytes,
    String difficulty = StudentLessonPricing.medium,
  }) async {
    _cancelTimers();

    final matchDelay = StudentLessonSessionConfig.useDemoTimers
        ? StudentLessonSessionConfig.demoMatchDelay
        : const Duration(seconds: 2);

    final matchKey = 'match-complete-$pendingId-$sessionToken';
    final extendKey = 'extend-$pendingId-$sessionToken';
    final candidates = StudentTutorDummyData.candidatesForSubject(subject);

    state = StudentMatchingSession(
      id: pendingId,
      subject: subject,
      difficulty: difficulty,
      questionSummary: questionSummary,
      problemImageBytes: problemImageBytes,
      status: StudentMatchingSessionStatus.matching,
      startedAt: DateTime.now(),
      matchDedupeKey: matchKey,
      extendDedupeKey: extendKey,
      candidateIds: candidates.map((tutor) => tutor.id).toList(),
    );

    _scheduleSelectingTutor(matchDelay, pendingId);

    return true;
  }

  void waitForSubjectExpert() {
    final current = state;
    if (current == null) return;

    _cancelTimers();

    state = current.copyWith(
      status: StudentMatchingSessionStatus.matching,
      waitingForSubjectExpert: true,
      hasWaitedForSubjectExpert: true,
      clearSelectedTutorId: true,
      startedAt: DateTime.now(),
    );

    _scheduleSubjectExpertCheck(current.id);
  }

  void _scheduleSubjectExpertCheck(String pendingId) {
    _subjectExpertWaitTimer?.cancel();

    final delay = StudentLessonSessionConfig.useDemoTimers
        ? StudentLessonSessionConfig.demoSubjectExpertDelay
        : const Duration(seconds: 5);

    _subjectExpertWaitTimer = Timer(delay, () async {
      final current = state;
      if (current == null || current.id != pendingId) return;
      if (current.status != StudentMatchingSessionStatus.matching) return;
      if (!current.waitingForSubjectExpert) return;

      final experts =
          StudentTutorDummyData.expertsAfterSubjectWait(current.subject);
      if (experts.isEmpty) {
        _scheduleSubjectExpertCheck(pendingId);
        return;
      }

      final dedupeKey = 'subject-expert-${current.matchDedupeKey}';
      await _ref.read(studentNotificationControllerProvider).deliverSubjectExpertAssigned(
            dedupeKey: dedupeKey,
            subject: current.subject,
          );

      if (state?.id != pendingId) return;

      state = current.copyWith(
        status: StudentMatchingSessionStatus.selectingTutor,
        waitingForSubjectExpert: false,
        candidateIds: experts.map((tutor) => tutor.id).toList(),
      );
    });
  }

  void _scheduleSelectingTutor(
    Duration delay,
    String pendingId,
  ) {
    _matchStateTimer = Timer(delay, () {
      final current = state;
      if (current == null || current.id != pendingId) return;

      state = current.copyWith(
        status: StudentMatchingSessionStatus.selectingTutor,
        waitingForSubjectExpert: false,
        candidateIds: current.candidateIds,
      );
    });
  }

  void selectTutor(String tutorId) {
    final current = state;
    if (current == null) return;
    if (current.status != StudentMatchingSessionStatus.selectingTutor) return;
    if (!current.candidateIds.contains(tutorId)) return;

    _connectionTimer?.cancel();
    _extensionTimer?.cancel();

    state = current.copyWith(
      selectedTutorId: tutorId,
      status: StudentMatchingSessionStatus.connecting,
    );

    final connectionDelay = StudentLessonSessionConfig.useDemoTimers
        ? StudentLessonSessionConfig.demoConnectionDelay
        : const Duration(seconds: 2);

    _connectionTimer = Timer(connectionDelay, () {
      final session = state;
      if (session == null || session.selectedTutorId != tutorId) return;

      final tutor = session.selectedTutor;
      if (tutor == null) return;

      _ref.read(studentNotificationControllerProvider).deliverMatchingComplete(
            dedupeKey: session.matchDedupeKey,
            tutorName: tutor.name,
            subject: session.subject,
          );

      state = session.copyWith(status: StudentMatchingSessionStatus.connected);

      final extensionDelay = StudentLessonSessionConfig.useDemoTimers
          ? StudentLessonSessionConfig.demoExtensionDelay
          : StudentLessonSessionConfig.sessionDuration -
              StudentLessonSessionConfig.extensionNoticeBeforeEnd;

      _extensionTimer = Timer(extensionDelay, () {
        final active = state;
        if (active == null || active.selectedTutorId != tutorId) return;
        if (active.status != StudentMatchingSessionStatus.connected) return;

        _ref.read(studentNotificationControllerProvider).deliverSessionExtension(
              dedupeKey: active.extendDedupeKey,
              tutorName: tutor.name,
              subject: active.subject,
            );
      });
    });
  }

  void returnToTutorSelection() {
    final current = state;
    if (current == null) return;
    if (current.status != StudentMatchingSessionStatus.connecting &&
        current.status != StudentMatchingSessionStatus.connected) {
      return;
    }

    _connectionTimer?.cancel();
    _extensionTimer?.cancel();

    final expanded = StudentTutorDummyData.expandedCandidatesForSubject(
      current.subject,
    );

    state = current.copyWith(
      status: StudentMatchingSessionStatus.selectingTutor,
      clearSelectedTutorId: true,
      candidateIds: expanded.map((tutor) => tutor.id).toList(),
    );
  }

  Future<void> cancelMatching() async {
    _cancelTimers();

    final session = state;
    if (session != null) {
      await _ref.read(studentNotificationControllerProvider).cancelScheduledKeys([
        session.matchDedupeKey,
        session.extendDedupeKey,
      ]);
    }

    state = null;
  }

  void _cancelTimers() {
    _matchStateTimer?.cancel();
    _subjectExpertWaitTimer?.cancel();
    _connectionTimer?.cancel();
    _extensionTimer?.cancel();
  }
}

final studentMatchingSessionProvider =
    StateNotifierProvider<StudentMatchingSessionNotifier, StudentMatchingSession?>(
  (ref) => StudentMatchingSessionNotifier(ref),
);
