import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
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
    try {
      final list = await _repository.getSearchingProblems(_tutorId);
      state = state.copyWith(
        problems: AsyncData(
          list.where((p) => !p.alreadyApplied).toList(),
        ),
      );
      _stomp.connect(
        _tutorId,
        removeProblem,
        onMatchRequested: onMatchRequested,
        onMatchCancelled: onMatchCancelled,
        onNewProblem: _onNewProblem,
      );
    } catch (e, st) {
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
    state = state.copyWith(matchCancelledMessage: message);
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
      state = state.copyWith(applications: AsyncData(list));
      final matchingIds = list
          .where((a) => a.status == 'PENDING' || a.status == 'CONFIRMING')
          .map((a) => a.problemId)
          .toList();
      _stomp.connect(
        _tutorId,
        _onProblemMatched,
        matchingProblemIds: matchingIds,
        onMatched: _removeByProblemId,
      );
    } catch (e, st) {
      state = state.copyWith(applications: AsyncError(e, st));
    }
  }

  Future<void> cancelApplication(int problemId) async {
    await _repository.cancelApplication(problemId, _tutorId);
    _removeByProblemId(problemId);
  }

  void _onProblemMatched(int problemId) => _removeByProblemId(problemId);

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
