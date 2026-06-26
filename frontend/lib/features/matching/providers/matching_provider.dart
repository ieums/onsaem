import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import '../../../routes/app_router.dart';
import '../models/searching_problem_model.dart';
import '../models/tutor_application_model.dart';
import '../repositories/matching_repository.dart';
import '../repositories/matching_stomp_service.dart';

const _sentinel = Object();

class MatchingState {
  const MatchingState({
    this.problems = const AsyncLoading(),
    this.matchRequestedProblemId,
    this.matchRequestedMessage,
    this.matchCancelledMessage,
  });

  final AsyncValue<List<SearchingProblemModel>> problems;
  final int? matchRequestedProblemId;
  final String? matchRequestedMessage;
  final String? matchCancelledMessage;

  MatchingState copyWith({
    AsyncValue<List<SearchingProblemModel>>? problems,
    Object? matchRequestedProblemId = _sentinel,
    Object? matchRequestedMessage = _sentinel,
    Object? matchCancelledMessage = _sentinel,
  }) {
    return MatchingState(
      problems: problems ?? this.problems,
      matchRequestedProblemId: matchRequestedProblemId == _sentinel
          ? this.matchRequestedProblemId
          : matchRequestedProblemId as int?,
      matchRequestedMessage: matchRequestedMessage == _sentinel
          ? this.matchRequestedMessage
          : matchRequestedMessage as String?,
      matchCancelledMessage: matchCancelledMessage == _sentinel
          ? this.matchCancelledMessage
          : matchCancelledMessage as String?,
    );
  }
}

class MatchingNotifier extends StateNotifier<MatchingState> {
  final MatchingRepository _repository;
  final MatchingStompService _stomp;
  final int _tutorId;

  MatchingNotifier({
    required MatchingRepository repository,
    required MatchingStompService stomp,
    required int tutorId,
  })  : _repository = repository,
        _stomp = stomp,
        _tutorId = tutorId,
        super(const MatchingState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(problems: const AsyncLoading());
    // STOMP는 목록 조회 성공/실패와 무관하게 먼저 연결한다.
    // (예전엔 getSearchingProblems가 실패하면 connect를 못 타 실시간이 죽었음)
    _stomp.connect(
      _tutorId,
      removeProblem,
      onMatchRequested: onMatchRequested,
      onMatchCancelled: onMatchCancelled,
      onNewProblem: _onNewProblem,
    );
    try {
      final list = await _repository.getSearchingProblems(_tutorId);
      if (!mounted) return; // 비동기 도중 화면 이탈로 dispose되면 state 건드리지 않음
      state = state.copyWith(
        problems: AsyncData(
          list.where((p) => !p.alreadyApplied).toList(),
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(problems: AsyncError(e, st));
    }
  }

  Future<void> applyToLesson(int problemId) async {
    await _repository.applyToLesson(problemId, _tutorId);
    removeProblem(problemId);
  }

  Future<void> rejectProblem(int problemId) async {
    await _repository.rejectProblem(problemId, _tutorId);
    removeProblem(problemId);
  }

  void removeProblem(int problemId) {
    state.problems.whenData((list) {
      state = state.copyWith(
        problems: AsyncData(
          list.where((p) => p.problemId != problemId).toList(),
        ),
      );
    });
  }

  Future<void> _onNewProblem(int problemId) async {
    try {
      final list = await _repository.getSearchingProblems(_tutorId);
      if (!mounted) return;
      state = state.copyWith(
        problems: AsyncData(
          list.where((p) => !p.alreadyApplied).toList(),
        ),
      );
    } catch (_) {}
  }

  void onMatchRequested(int problemId, int tutorId, String message) {
    state = state.copyWith(
      matchRequestedProblemId: problemId,
      matchRequestedMessage: message,
    );
  }

  void onMatchCancelled(String message) {
    // 학생과 동일하게 요청도 비워서, 화면이 열려있는 매칭 요청 다이얼로그를 닫을 수 있게 한다.
    state = state.copyWith(
      matchCancelledMessage: message,
      matchRequestedProblemId: null,
      matchRequestedMessage: null,
    );
  }

  Future<void> confirmMatch(int problemId) async {
    await _repository.confirmMatch(problemId, _tutorId);
    state = state.copyWith(
      matchRequestedProblemId: null,
      matchRequestedMessage: null,
    );
  }

  Future<void> cancelConfirm(int problemId) async {
    await _repository.cancelConfirm(problemId, _tutorId);
    state = state.copyWith(
      matchRequestedProblemId: null,
      matchRequestedMessage: null,
    );
  }

  void clearMatchCancelled() {
    state = state.copyWith(matchCancelledMessage: null);
  }

  Future<void> refresh() => _init();

  @override
  void dispose() {
    _stomp.disconnect();
    super.dispose();
  }
}

final matchingProvider = StateNotifierProvider.autoDispose<MatchingNotifier, MatchingState>((ref) {
  final tutorId = ref.watch(currentUserProvider)?.id ?? 0;
  return MatchingNotifier(
    repository: MatchingRepository(),
    stomp: MatchingStompService(),
    tutorId: tutorId,
  );
});

// ─── 강사 신청 리스트 ─────────────────────────────────────────────────────────

class TutorApplicationsState {
  const TutorApplicationsState({
    this.applications = const AsyncLoading(),
  });

  final AsyncValue<List<TutorApplicationModel>> applications;

  TutorApplicationsState copyWith({
    AsyncValue<List<TutorApplicationModel>>? applications,
  }) {
    return TutorApplicationsState(
      applications: applications ?? this.applications,
    );
  }
}

class TutorApplicationsNotifier
    extends StateNotifier<TutorApplicationsState> {
  final MatchingRepository _repository;
  final MatchingStompService _stomp;
  final int _tutorId;

  TutorApplicationsNotifier({
    required MatchingRepository repository,
    required MatchingStompService stomp,
    required int tutorId,
  })  : _repository = repository,
        _stomp = stomp,
        _tutorId = tutorId,
        super(const TutorApplicationsState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(applications: const AsyncLoading());
    try {
      final list = await _repository.getTutorApplications(_tutorId);
      if (!mounted) return; // dispose 후 state 접근 방지
      state = state.copyWith(applications: AsyncData(list));
      final matchingIds = list
          .where((a) => a.status == 'PENDING' || a.status == 'CONFIRMING')
          .map((a) => a.problemId)
          .toList();
      _stomp.connect(
        _tutorId,
        (problemId) => _removeByProblemId(problemId),
        matchingProblemIds: matchingIds,
        onMatched: (problemId, channelName, imageUrls, subject) {
          _removeByProblemId(problemId);
          if (channelName.isNotEmpty) {
            appRouter.go('/lesson', extra: {
              'channelName': channelName,
              'imageUrls': imageUrls,
              'subject': subject,
            });
          }
        },
      );
    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(applications: AsyncError(e, st));
    }
  }

  Future<void> cancelApplication(int problemId) async {
    await _repository.cancelApplication(problemId, _tutorId);
    _removeByProblemId(problemId);
  }

  /// 재입장한 강사가 대기 중인 매칭 요청(CONFIRMING)을 신청 목록에서 직접 확정한다.
  /// 양쪽(강사·학생)이 다 확정되면 백엔드가 MATCHED를 보내고, _init의 onMatched가 강의실로 이동시킨다.
  Future<void> confirmMatch(int problemId) async {
    await _repository.confirmMatch(problemId, _tutorId);
  }

  void _removeByProblemId(int problemId) {
    state.applications.whenData((list) {
      state = state.copyWith(
        applications: AsyncData(
          list.where((a) => a.problemId != problemId).toList(),
        ),
      );
    });
  }

  Future<void> refresh() => _init();

  @override
  void dispose() {
    _stomp.disconnect();
    super.dispose();
  }
}

final tutorApplicationsProvider = StateNotifierProvider.autoDispose<
    TutorApplicationsNotifier, TutorApplicationsState>((ref) {
  final tutorId = ref.watch(currentUserProvider)?.id ?? 0;
  return TutorApplicationsNotifier(
    repository: MatchingRepository(),
    stomp: MatchingStompService(),
    tutorId: tutorId,
  );
});
