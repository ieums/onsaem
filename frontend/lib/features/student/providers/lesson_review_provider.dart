import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/api_error.dart';
import '../data/lesson_review_repository.dart';
import '../data/models/lesson_review_message.dart';
import '../data/models/lesson_review_resources.dart';
import '../data/models/lesson_review_session.dart';
import '../data/models/review_lesson_item.dart';

// ─── 복습 목록 (StudentLessonsScreen용) ───────────────────────────
// 완료된 강의 전부 — 전사 전이면 ready=false("복습 준비중"), 완료되면 진입 가능.
final reviewLessonsProvider =
    FutureProvider.autoDispose<List<ReviewLessonItem>>((ref) {
  return ref.read(lessonReviewRepositoryProvider).listReviewLessons();
});

// ─── 세션 목록 (현재는 미사용, 호환용으로 유지) ───────────────────
final lessonReviewSessionsProvider =
    FutureProvider.autoDispose<List<LessonReviewSession>>((ref) {
  return ref.read(lessonReviewRepositoryProvider).listSessions();
});

// ─── 채팅 상태 ────────────────────────────────────────────────────
class LessonReviewChatState {
  final LessonReviewSession? session;
  final List<LessonReviewMessage> messages;
  final LessonReviewResources? resources;
  final bool isInitializing;
  final bool isSending;
  final String? error;

  const LessonReviewChatState({
    this.session,
    this.messages = const [],
    this.resources,
    this.isInitializing = false,
    this.isSending = false,
    this.error,
  });

  LessonReviewChatState copyWith({
    LessonReviewSession? session,
    List<LessonReviewMessage>? messages,
    LessonReviewResources? resources,
    bool? isInitializing,
    bool? isSending,
    String? error,
  }) {
    return LessonReviewChatState(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      resources: resources ?? this.resources,
      isInitializing: isInitializing ?? this.isInitializing,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class LessonReviewChatNotifier
    extends StateNotifier<LessonReviewChatState> {
  final LessonReviewRepository _repo;

  LessonReviewChatNotifier(this._repo)
      : super(const LessonReviewChatState());

  // 복습 화면 진입 시 호출
  // - 이 lessonId로 기존 세션 있으면 재사용, 없으면 새로 생성
  // - 메시지 히스토리 + 영상/PDF URL 동시 로드
  Future<void> init(int lessonId) async {
    state = state.copyWith(isInitializing: true, error: null);
    try {
      final sessions = await _repo.listSessions();
      final existing = sessions
          .where((s) => s.lessonId == lessonId)
          .toList();

      final session = existing.isNotEmpty
          ? existing.first
          : await _repo.createSession(lessonId);

      final messages = await _repo.getMessages(session.sessionId);
      final resources = await _repo.getResources(lessonId);

      state = state.copyWith(
        session: session,
        messages: messages,
        resources: resources,
        isInitializing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: apiErrorMessage(e),
      );
    }
  }

  // 메시지 전송
  // 1) 학생 메시지 즉시 UI에 추가 (낙관적)
  // 2) API 호출
  // 3) AI 응답 추가
  Future<void> sendMessage(String content) async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null || state.isSending) return;

    final optimistic = LessonReviewMessage(
      messageId: -1,
      role: LessonReviewRole.user,
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
}

final lessonReviewChatProvider = StateNotifierProvider.autoDispose<
    LessonReviewChatNotifier, LessonReviewChatState>((ref) {
  return LessonReviewChatNotifier(ref.read(lessonReviewRepositoryProvider));
});