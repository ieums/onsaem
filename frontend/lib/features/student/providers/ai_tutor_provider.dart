import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/api_error.dart';
import '../data/ai_tutor_repository.dart';
import '../data/models/ai_tutor_message.dart';
import '../data/models/ai_tutor_session.dart';
import '../data/models/ai_tutor_problem.dart';

/// 진행 중(종료 안 됐고 질문을 한 번이라도 한) AI 튜터 세션 — 목록 상단 '진행 중' 섹션용.
/// 입장만 하고 질문 안 한 빈 세션(messageCount==0)은 제외해 '이어서'가 잘못 뜨지 않게 한다.
/// 최근 활동순.
final aiTutorActiveSessionsProvider =
    FutureProvider.autoDispose<List<AiTutorSession>>((ref) async {
  final repo = ref.watch(aiTutorRepositoryProvider);
  final sessions = await repo.listSessions();
  return sessions.where((s) => !s.status.isClosed && s.hasStarted).toList()
    ..sort((a, b) => (b.updatedAt ?? b.createdAt)
        .compareTo(a.updatedAt ?? a.createdAt));
});

class AiTutorChatState {
  final AiTutorSession? session;
  final AiTutorProblem? problem;
  final List<AiTutorMessage> messages;
  final bool isInitializing;
  final bool isSending;
  final String? error;

  const AiTutorChatState({
    this.session,
    this.problem,
    this.messages = const [],
    this.isInitializing = false,
    this.isSending = false,
    this.error,
  });

  AiTutorChatState copyWith({
    AiTutorSession? session,
    AiTutorProblem? problem,
    List<AiTutorMessage>? messages,
    bool? isInitializing,
    bool? isSending,
    String? error,
  }) {
    return AiTutorChatState(
      session: session ?? this.session,
      problem: problem ?? this.problem,
      messages: messages ?? this.messages,
      isInitializing: isInitializing ?? this.isInitializing,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class AiTutorChatNotifier extends StateNotifier<AiTutorChatState> {
  final AiTutorRepository _repo;

  AiTutorChatNotifier(this._repo) : super(const AiTutorChatState());

  // 진입 시: 문제 정보 조회 + 이 problemId 세션 재사용/생성 → 메시지 로드
  Future<void> init(int problemId) async {
    state = state.copyWith(isInitializing: true, error: null);
    try {
      // 상단 배너용 문제 정보 — 실패해도 채팅은 계속 진행(best-effort)
      AiTutorProblem? problem;
      try {
        problem = await _repo.getProblem(problemId);
      } catch (_) {}

      final sessions = await _repo.listSessions();
      final existing = sessions
          .where((s) => s.problemId == problemId && !s.status.isClosed)
          .toList();

      final session = existing.isNotEmpty
          ? existing.first
          : await _repo.createSession(problemId);

      final messages = await _repo.getMessages(session.sessionId);

      state = state.copyWith(
        session: session,
        problem: problem,
        messages: messages,
        isInitializing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: apiErrorMessage(e),
      );
    }
  }

  // 메시지 전송 (낙관적 업데이트)
  Future<void> sendMessage(String content) async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null || state.isSending) return;

    final optimistic = AiTutorMessage(
      messageId: -1,
      role: AiTutorRole.user,
      content: content,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, optimistic],
      isSending: true,
      error: null,
    );

    try {
      final aiMessage = await _repo.sendMessage(sessionId, content);
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: state.messages.where((m) => m.messageId != -1).toList(),
        isSending: false,
        error: apiErrorMessage(e),
      );
    }
  }

  // 세션 종료 → 성공하면 true
  Future<bool> close() async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null) return false;
    try {
      await _repo.closeSession(sessionId);
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }
}

final aiTutorChatProvider = StateNotifierProvider.autoDispose<
    AiTutorChatNotifier, AiTutorChatState>((ref) {
  return AiTutorChatNotifier(ref.read(aiTutorRepositoryProvider));
});