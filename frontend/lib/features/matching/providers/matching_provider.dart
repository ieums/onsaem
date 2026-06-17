import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import '../models/searching_problem_model.dart';
import '../repositories/matching_repository.dart';
import '../repositories/matching_stomp_service.dart';

class MatchingState {
  const MatchingState({
    this.problems = const AsyncLoading(),
  });

  final AsyncValue<List<SearchingProblemModel>> problems;

  MatchingState copyWith({
    AsyncValue<List<SearchingProblemModel>>? problems,
  }) {
    return MatchingState(problems: problems ?? this.problems);
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
      state = state.copyWith(problems: AsyncData(list));
      _stomp.connect(_tutorId, removeProblem);
    } catch (e, st) {
      state = state.copyWith(problems: AsyncError(e, st));
    }
  }

  Future<void> applyToLesson(int problemId) async {
    await _repository.applyToLesson(problemId, _tutorId);
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
