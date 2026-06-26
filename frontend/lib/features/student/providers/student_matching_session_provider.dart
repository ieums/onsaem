import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/features/matching/repositories/matching_repository.dart';
import 'package:ieum/features/student/models/applicant_model.dart';
import 'package:ieum/features/student/models/student_lesson_pricing.dart';
import 'package:ieum/features/student/models/student_tutor_profile.dart';
import 'package:ieum/features/student/repositories/student_matching_stomp_service.dart';

enum StudentMatchingSessionStatus {
  matching,
  selectingTutor,
  connecting,
  connected,
}

class StudentMatchingSession {
  const StudentMatchingSession({
    required this.problemId,
    required this.subject,
    required this.questionSummary,
    required this.status,
    required this.startedAt,
    required this.applicants,
    required this.imageUrls,
    this.problemImageBytes,
    this.selectedTutorId,
    this.channelName,
    this.matchRequestedTutorId,
    this.matchCancelledMessage,
    this.isSearchExpiringSoon = false,
    this.tutorProfileImageUrl,
    this.studentProfileImageUrl,
  });

  final int problemId;
  final String subject;
  final String questionSummary;
  final StudentMatchingSessionStatus status;
  final DateTime startedAt;
  final List<ApplicantModel> applicants;
  final List<String> imageUrls;
  final Uint8List? problemImageBytes;
  final String? selectedTutorId;
  final String? channelName;
  final int? matchRequestedTutorId;
  final String? matchCancelledMessage;
  final bool isSearchExpiringSoon;
  final String? tutorProfileImageUrl;
  final String? studentProfileImageUrl;

  int get lessonPrice => StudentLessonPricing.priceForDifficulty(StudentLessonPricing.medium);

  List<StudentTutorProfile> get candidates =>
      applicants.map(StudentTutorProfile.fromApplicant).toList();

  // 홈 화면의 '매칭 대기 중인 질문' 카드 노출 여부.
  // false로 끄면 홈에서 안 보임(매칭 세션 로직 자체는 그대로). 다시 보이게 하려면 true.
  bool get showOnHomePending => false;

  StudentTutorProfile? get selectedTutor {
    if (selectedTutorId == null) return null;
    final applicant = applicants
        .where((a) => a.tutorId.toString() == selectedTutorId)
        .firstOrNull;
    if (applicant == null) return null;
    return StudentTutorProfile.fromApplicant(applicant);
  }

  StudentMatchingSession copyWith({
    int? problemId,
    String? subject,
    String? questionSummary,
    StudentMatchingSessionStatus? status,
    DateTime? startedAt,
    List<ApplicantModel>? applicants,
    List<String>? imageUrls,
    Uint8List? problemImageBytes,
    Object? selectedTutorId = _sentinel,
    Object? channelName = _sentinel,
    Object? matchRequestedTutorId = _sentinel,
    Object? matchCancelledMessage = _sentinel,
    bool? isSearchExpiringSoon,
    Object? tutorProfileImageUrl = _sentinel,
    Object? studentProfileImageUrl = _sentinel,
  }) {
    return StudentMatchingSession(
      problemId: problemId ?? this.problemId,
      subject: subject ?? this.subject,
      questionSummary: questionSummary ?? this.questionSummary,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      applicants: applicants ?? this.applicants,
      imageUrls: imageUrls ?? this.imageUrls,
      problemImageBytes: problemImageBytes ?? this.problemImageBytes,
      selectedTutorId: selectedTutorId == _sentinel
          ? this.selectedTutorId
          : selectedTutorId as String?,
      channelName: channelName == _sentinel
          ? this.channelName
          : channelName as String?,
      matchRequestedTutorId: matchRequestedTutorId == _sentinel
          ? this.matchRequestedTutorId
          : matchRequestedTutorId as int?,
      matchCancelledMessage: matchCancelledMessage == _sentinel
          ? this.matchCancelledMessage
          : matchCancelledMessage as String?,
      isSearchExpiringSoon:
          isSearchExpiringSoon ?? this.isSearchExpiringSoon,
      tutorProfileImageUrl: tutorProfileImageUrl == _sentinel
          ? this.tutorProfileImageUrl
          : tutorProfileImageUrl as String?,
      studentProfileImageUrl: studentProfileImageUrl == _sentinel
          ? this.studentProfileImageUrl
          : studentProfileImageUrl as String?,
    );
  }
}

const _sentinel = Object();

class StudentMatchingSessionNotifier
    extends StateNotifier<StudentMatchingSession?> {
  StudentMatchingSessionNotifier({
    required MatchingRepository repo,
    required StudentMatchingStompService stomp,
  })  : _repo = repo,
        _stomp = stomp,
        super(null);

  final MatchingRepository _repo;
  final StudentMatchingStompService _stomp;

  Future<void> startMatching({
    required int problemId,
    required int studentId,
    required String subject,
    required String questionSummary,
    Uint8List? problemImageBytes,
  }) async {
    state = StudentMatchingSession(
      problemId: problemId,
      subject: subject,
      questionSummary: questionSummary,
      problemImageBytes: problemImageBytes,
      status: StudentMatchingSessionStatus.matching,
      startedAt: DateTime.now(),
      applicants: const [],
      imageUrls: const [],
    );

    await _repo.startMatching(problemId);

    _connectStomp(studentId, problemId);
  }

  Future<void> resumeMatching({
    required int problemId,
    required int studentId,
    required String subject,
    required String questionSummary,
  }) async {
    final applicants = await _repo.getApplicants(problemId);
    state = StudentMatchingSession(
      problemId: problemId,
      subject: subject,
      questionSummary: questionSummary,
      status: applicants.isNotEmpty
          ? StudentMatchingSessionStatus.selectingTutor
          : StudentMatchingSessionStatus.matching,
      startedAt: DateTime.now(),
      applicants: applicants,
      imageUrls: const [],
    );
    _connectStomp(studentId, problemId);
  }

  void _connectStomp(int studentId, int problemId) {
    _stomp.connect(
      studentId,
      problemId,
      onTutorApplied: (_) async {
        final list = await _repo.getApplicants(problemId);
        if (state == null) return;
        state = state!.copyWith(
          applicants: list,
          status: list.isNotEmpty
              ? StudentMatchingSessionStatus.selectingTutor
              : StudentMatchingSessionStatus.matching,
        );
      },
      onTutorCancelled: (tutorId) {
        if (state == null) return;
        state = state!.copyWith(
          applicants:
              state!.applicants.where((a) => a.tutorId != tutorId).toList(),
        );
      },
      onMatchRequested: (_, tutorId, msg) {
        if (state == null) return;
        state = state!.copyWith(matchRequestedTutorId: tutorId);
      },
      onMatchCancelled: (msg) {
        if (state == null) return;
        final cancelledTutorId = state!.matchRequestedTutorId;
        state = state!.copyWith(
          matchCancelledMessage: msg,
          matchRequestedTutorId: null,
          selectedTutorId: null,
          status: StudentMatchingSessionStatus.selectingTutor,
          applicants: cancelledTutorId == null
              ? state!.applicants
              : state!.applicants
                  .where((a) => a.tutorId != cancelledTutorId)
                  .toList(),
        );
      },
      onSearchExpiringSoon: () {
        if (state == null) return;
        state = state!.copyWith(isSearchExpiringSoon: true);
      },
      onSearchExpired: () => cancelMatching(),
      onMatched: (channelName, imageUrls, subject, tutorProfileImageUrl, studentProfileImageUrl) {
        if (state == null) return;
        state = state!.copyWith(
          channelName: channelName,
          imageUrls: imageUrls,
          subject: subject ?? state!.subject,
          status: StudentMatchingSessionStatus.connected,
          tutorProfileImageUrl: tutorProfileImageUrl,
          studentProfileImageUrl: studentProfileImageUrl,
        );
      },
      onTutorUnavailable: (id) => _updateApplicantAvailability(id, false),
      onTutorAvailable: (id) => _updateApplicantAvailability(id, true),
    );
  }

  Future<void> selectTutor(String tutorId) async {
    if (state == null) return;
    await _repo.acceptTutor(state!.problemId, int.parse(tutorId));
    state = state!.copyWith(
      selectedTutorId: tutorId,
      status: StudentMatchingSessionStatus.connecting,
    );
  }

  Future<void> confirmMatch(int tutorId) async {
    if (state == null) return;
    await _repo.confirmMatchStudent(state!.problemId, tutorId);
    state = state!.copyWith(matchRequestedTutorId: null);
  }

  Future<void> cancelConfirm(int tutorId) async {
    if (state == null) return;
    await _repo.cancelConfirmStudent(state!.problemId, tutorId);
    state = state!.copyWith(matchRequestedTutorId: null);
  }

  Future<void> cancelMatching() async {
    final current = state;
    state = null;
    _stomp.disconnect();
    if (current != null) {
      try {
        await _repo.cancelProblem(current.problemId);
      } catch (_) {}
    }
  }

  Future<void> extendSearch({int minutes = 30}) async {
    if (state == null) return;
    await _repo.extendSearch(state!.problemId, minutes: minutes);
    state = state!.copyWith(isSearchExpiringSoon: false);
  }

  void clearMatchCancelledMessage() {
    if (state == null) return;
    state = state!.copyWith(matchCancelledMessage: null);
  }

  void _updateApplicantAvailability(int tutorId, bool available) {
    if (state == null) return;
    state = state!.copyWith(
      applicants: state!.applicants
          .map((a) =>
              a.tutorId == tutorId ? a.copyWith(isAvailable: available) : a)
          .toList(),
    );
  }

  @override
  void dispose() {
    _stomp.disconnect();
    super.dispose();
  }
}

final studentMatchingSessionProvider = StateNotifierProvider<
    StudentMatchingSessionNotifier, StudentMatchingSession?>(
  (ref) => StudentMatchingSessionNotifier(
    repo: MatchingRepository(),
    stomp: StudentMatchingStompService(),
  ),
);
