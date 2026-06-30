import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/features/matching/repositories/matching_repository.dart';
import 'package:ieum/features/student/models/applicant_model.dart';
import 'package:ieum/features/student/models/student_lesson_pricing.dart';
import 'package:ieum/features/student/models/student_tutor_profile.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/providers/student_notification_provider.dart';
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
    required Ref ref,
  })  : _repo = repo,
        _stomp = stomp,
        _ref = ref,
        super(null);

  final MatchingRepository _repo;
  final StudentMatchingStompService _stomp;
  final Ref _ref;

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

  /// 앱 재실행 후 놓친 매칭 수락 복구 — 세션을 다시 연결하고 수락/거절 다이얼로그를 띄운다.
  /// (resumeMatching으로 STOMP를 살려야 수락 시 onMatched를 받아 강의실로 이동된다)
  Future<void> restorePendingConfirm({
    required int problemId,
    required int studentId,
    required String subject,
    required String questionSummary,
    required int tutorId,
  }) async {
    await resumeMatching(
      problemId: problemId,
      studentId: studentId,
      subject: subject,
      questionSummary: questionSummary,
    );
    if (state == null) return;
    state = state!.copyWith(matchRequestedTutorId: tutorId);
  }

  void _connectStomp(int studentId, int problemId) {
    _stomp.connect(
      studentId,
      problemId,
      onTutorApplied: (_) async {
        final list = await _repo.getApplicants(problemId);
        if (state == null) return;
        final hadApplicants = state!.applicants.isNotEmpty;
        state = state!.copyWith(
          applicants: list,
          status: list.isNotEmpty
              ? StudentMatchingSessionStatus.selectingTutor
              : StudentMatchingSessionStatus.matching,
        );
        // 홈/목록의 '지원 강사 N명'도 실시간 반영(세션이 떠 있는 동안).
        _ref.invalidate(studentProblemsProvider);
        // 첫 강사 신청 시 알림함 + 배너 (강사가 신청했어요 → 선택하세요)
        if (!hadApplicants && list.isNotEmpty) {
          await _ref
              .read(studentNotificationControllerProvider)
              .deliverSubjectExpertAssigned(
                dedupeKey: 'applied-$problemId',
                subject: state!.subject,
              );
        }
      },
      onTutorCancelled: (tutorId) {
        if (state == null) return;
        state = state!.copyWith(
          applicants:
              state!.applicants.where((a) => a.tutorId != tutorId).toList(),
        );
        _ref.invalidate(studentProblemsProvider);
      },
      onMatchRequested: (_, tutorId, msg) {
        if (state == null) return;
        state = state!.copyWith(matchRequestedTutorId: tutorId);
      },
      onMatchCancelled: (tutorId, msg) {
        if (state == null) return;
        // 제거할 강사: 서버 메시지의 tutorId 우선, 없으면 로컬 캐시(matchRequestedTutorId) 폴백.
        // (수락 후엔 matchRequestedTutorId가 null이라 메시지 tutorId가 있어야 정확히 제거됨)
        final cancelledTutorId = tutorId ?? state!.matchRequestedTutorId;
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
      // 수업 시작/종료 → '수업 중'(isInLesson) 갱신. (카드가 읽는 필드)
      onTutorUnavailable: (id) => _setApplicantInLesson(id, true),
      onTutorAvailable: (id) => _setApplicantInLesson(id, false),
      // 온/오프 토글 → 온라인 배지(isOnline) 갱신.
      onTutorOnline: (id) => _setApplicantOnline(id, true),
      onTutorOffline: (id) => _setApplicantOnline(id, false),
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
    // 거절하면 그 강사는 목록에서 빼고, 다시 강사 선택 화면으로 돌아간다(남은 강사 선택 가능).
    final remaining =
        state!.applicants.where((a) => a.tutorId != tutorId).toList();
    state = state!.copyWith(
      matchRequestedTutorId: null,
      selectedTutorId: null,
      status: remaining.isNotEmpty
          ? StudentMatchingSessionStatus.selectingTutor
          : StudentMatchingSessionStatus.matching,
      applicants: remaining,
    );
    // 홈/목록의 지원 강사 수도 갱신.
    _ref.invalidate(studentProblemsProvider);
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
  /// 수업 완료 등 정상 종료 — 문제는 살리고(복습/이미지 보존) 세션만 비운다.
  void clearSession() {
    state = null;
    _stomp.disconnect();
  }
  
  Future<void> extendSearch({int minutes = 1440}) async {
    if (state == null) return;
    await _repo.extendSearch(state!.problemId, minutes: minutes);
    state = state!.copyWith(isSearchExpiringSoon: false);
  }

  void clearMatchCancelledMessage() {
    if (state == null) return;
    state = state!.copyWith(matchCancelledMessage: null);
  }

  // 라이브로 '수업 중' 상태 갱신 — 카드는 isInLesson을 읽어 배지/선택차단을 결정한다.
  void _setApplicantInLesson(int tutorId, bool inLesson) {
    if (state == null) return;
    state = state!.copyWith(
      applicants: state!.applicants
          .map((a) =>
              a.tutorId == tutorId ? a.copyWith(isInLesson: inLesson) : a)
          .toList(),
    );
  }

  // 라이브로 온라인/오프라인 갱신 — 카드는 isOnline으로 배지를 표시한다.
  void _setApplicantOnline(int tutorId, bool online) {
    if (state == null) return;
    state = state!.copyWith(
      applicants: state!.applicants
          .map((a) => a.tutorId == tutorId ? a.copyWith(isOnline: online) : a)
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
    ref: ref,
  ),
);
