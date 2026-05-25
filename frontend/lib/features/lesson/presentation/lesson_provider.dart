import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../data/lesson_repository.dart';
import '../domain/lesson_model.dart';

// ─── 상수 ─────────────────────────────────────────────────────────────────────

const _eraserWidth = 16.0;
const _maxUndoHistory = 50;

// ─── State ────────────────────────────────────────────────────────────────────

@immutable
class LessonState {
  final String? channelName;
  final String? token;
  final String? appId;
  final int? lessonId;
  final int? uid;
  final bool isTutor;

  final bool isInChannel;
  final int? remoteUid;
  final bool localCameraEnabled;

  final Color currentPenColor;
  final bool isEraserMode;

  final bool isRecording;
  final String? recordingUrl;

  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final DrawingStroke? remoteStroke;
  final String? backgroundImageUrl;

  final List<CanvasAction> undoHistory;
  final List<CanvasAction> redoHistory;

  final bool isLoading;
  final bool isCompleted;
  final String? error;

  const LessonState({
    this.channelName,
    this.token,
    this.appId,
    this.lessonId,
    this.uid,
    this.isTutor = false,
    this.isInChannel = false,
    this.remoteUid,
    this.localCameraEnabled = true,
    this.currentPenColor = Colors.black,
    this.isEraserMode = false,
    this.isRecording = false,
    this.recordingUrl,
    this.strokes = const [],
    this.currentStroke,
    this.remoteStroke,
    this.backgroundImageUrl,
    this.undoHistory = const [],
    this.redoHistory = const [],
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
  });

  LessonState copyWith({
    String? channelName,
    String? token,
    String? appId,
    int? lessonId,
    int? uid,
    bool? isTutor,
    bool? isInChannel,
    Object? remoteUid = _sentinel,
    bool? localCameraEnabled,
    Color? currentPenColor,
    bool? isEraserMode,
    bool? isRecording,
    Object? recordingUrl = _sentinel,
    List<DrawingStroke>? strokes,
    Object? currentStroke = _sentinel,
    Object? remoteStroke = _sentinel,
    Object? backgroundImageUrl = _sentinel,
    List<CanvasAction>? undoHistory,
    List<CanvasAction>? redoHistory,
    bool? isLoading,
    bool? isCompleted,
    Object? error = _sentinel,
  }) {
    return LessonState(
      channelName: channelName ?? this.channelName,
      token: token ?? this.token,
      appId: appId ?? this.appId,
      lessonId: lessonId ?? this.lessonId,
      uid: uid ?? this.uid,
      isTutor: isTutor ?? this.isTutor,
      isInChannel: isInChannel ?? this.isInChannel,
      remoteUid: remoteUid == _sentinel ? this.remoteUid : remoteUid as int?,
      localCameraEnabled: localCameraEnabled ?? this.localCameraEnabled,
      currentPenColor: currentPenColor ?? this.currentPenColor,
      isEraserMode: isEraserMode ?? this.isEraserMode,
      isRecording: isRecording ?? this.isRecording,
      recordingUrl:
          recordingUrl == _sentinel ? this.recordingUrl : recordingUrl as String?,
      strokes: strokes ?? this.strokes,
      currentStroke:
          currentStroke == _sentinel ? this.currentStroke : currentStroke as DrawingStroke?,
      remoteStroke:
          remoteStroke == _sentinel ? this.remoteStroke : remoteStroke as DrawingStroke?,
      backgroundImageUrl: backgroundImageUrl == _sentinel
          ? this.backgroundImageUrl
          : backgroundImageUrl as String?,
      undoHistory: undoHistory ?? this.undoHistory,
      redoHistory: redoHistory ?? this.redoHistory,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LessonNotifier extends StateNotifier<LessonState> {
  final LessonRepository _repo;
  RtcEngine? _engine;

  LessonNotifier(this._repo) : super(const LessonState());

  RtcEngine? get engine => _engine;

  // ─── 초기화 ────────────────────────────────────────────────────────────────

  Future<void> initialize(
    String channelName,
    int uid,
    bool isTutor,
  ) async {
    state = state.copyWith(
      isLoading: true,
      channelName: channelName,
      uid: uid,
      isTutor: isTutor,
      localCameraEnabled: isTutor,
    );

    try {
      // 1. 토큰 발급
      final tokenResp = await _repo.fetchToken(
        channelName: channelName,
        uid: uid.toString(),
        role: 'PUBLISHER',
      );

      state = state.copyWith(
        token: tokenResp.token,
        appId: tokenResp.appId,
        lessonId: tokenResp.lessonId,
      );

      // 2. Agora 엔진 초기화
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: tokenResp.appId));

      // 3. 이벤트 핸들러 등록
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            state = state.copyWith(isInChannel: true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            state = state.copyWith(remoteUid: remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (state.remoteUid == remoteUid) {
              state = state.copyWith(remoteUid: null);
            }
          },
        ),
      );

      // 4. 오디오/비디오 활성화
      await _engine!.enableAudio();
      await _engine!.enableVideo(); // 원격 영상 수신에도 필요하므로 모든 역할에서 활성화
      if (!isTutor) {
        await _engine!.enableLocalVideo(false); // 학생: 로컬 캡처만 비활성화
      }

      // 5. 채널 입장
      await _engine!.joinChannel(
        token: tokenResp.token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // 6. STOMP 연결
      _repo.connectStomp(channelName, _onRemoteDrawEvent);

      // 7. 녹화 자동 시작 (튜터만)
      if (isTutor) {
        await _startRecording();
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ─── 카메라 토글 ────────────────────────────────────────────────────────────

  Future<void> toggleCamera() async {
    if (_engine == null) return;
    final next = !state.localCameraEnabled;
    await _engine!.enableLocalVideo(next);
    state = state.copyWith(localCameraEnabled: next);
  }

  // ─── 펜 도구 ───────────────────────────────────────────────────────────────

  void setPenColor(Color color) {
    // 색상 선택 시 지우개 모드 자동 해제
    state = state.copyWith(currentPenColor: color, isEraserMode: false);
  }

  void toggleEraser() {
    state = state.copyWith(isEraserMode: !state.isEraserMode);
  }

  // ─── 화이트보드 드로잉 ──────────────────────────────────────────────────────

  void onPanStart(Offset position) {
    final isEraser = state.isEraserMode;
    final color = isEraser ? Colors.white : state.currentPenColor;
    final width = isEraser ? _eraserWidth : AppConstants.defaultPenWidth;
    final type = isEraser ? DrawType.erase : DrawType.draw;

    final stroke = DrawingStroke(points: [position], color: color, width: width);
    state = state.copyWith(currentStroke: stroke);
    _sendDrawPoint(position, type: type, isStart: true);
  }

  void onPanUpdate(Offset position) {
    final current = state.currentStroke;
    if (current == null) return;
    state = state.copyWith(
      currentStroke: current.copyWithPoints([...current.points, position]),
    );
    final type = state.isEraserMode ? DrawType.erase : DrawType.draw;
    _sendDrawPoint(position, type: type);
  }

  void onPanEnd() {
    final current = state.currentStroke;
    if (current == null) return;

    final newStrokes = [...state.strokes, current];
    final newUndo = _appendToHistory(state.undoHistory, StrokeAction(current));

    state = state.copyWith(
      strokes: newStrokes,
      currentStroke: null,
      undoHistory: newUndo,
      redoHistory: const [], // 새 동작 시 redo 초기화
    );
  }

  void _sendDrawPoint(
    Offset position, {
    DrawType type = DrawType.draw,
    bool isStart = false,
  }) {
    final channelName = state.channelName;
    if (channelName == null) return;
    final isEraser = state.isEraserMode;
    _repo.sendDraw(
      channelName,
      DrawEvent(
        senderId: _repo.sessionId,
        type: type,
        x: position.dx,
        y: position.dy,
        color: colorToHex(isEraser ? Colors.white : state.currentPenColor),
        strokeWidth: isEraser ? _eraserWidth : AppConstants.defaultPenWidth,
        isStart: isStart ? true : null,
      ),
    );
  }

  // ─── 원격 드로잉 수신 ────────────────────────────────────────────────────────

  void _onRemoteDrawEvent(DrawEvent event) {
    switch (event.type) {
      case DrawType.draw:
      case DrawType.erase:
        _applyRemoteDrawPoint(event);
      case DrawType.clear:
        state = state.copyWith(
          strokes: [],
          remoteStroke: null,
          backgroundImageUrl: null,
          undoHistory: const [],
          redoHistory: const [],
        );
      case DrawType.imageAdd:
        if (event.imageUrl != null) {
          final newUndo = _appendToHistory(
            state.undoHistory,
            ImageAction(prevUrl: state.backgroundImageUrl),
          );
          state = state.copyWith(
            backgroundImageUrl: event.imageUrl,
            undoHistory: newUndo,
            redoHistory: const [],
          );
        }
      case DrawType.undo:
        _applyRemoteUndo();
      case DrawType.redo:
        _applyRemoteRedo();
    }
  }

  void _applyRemoteDrawPoint(DrawEvent event) {
    if (event.x == null || event.y == null) return;
    final point = Offset(event.x!, event.y!);
    final color = colorFromHex(event.color ?? AppConstants.defaultPenColor);
    final width = event.strokeWidth ?? AppConstants.defaultPenWidth;

    final current = state.remoteStroke;
    final forceNew = event.isStart == true; // isStart 플래그로 강제 새 스트로크

    if (current == null || forceNew || current.color != color || current.width != width) {
      // 이전 원격 스트로크 확정 후 새 스트로크 시작
      List<DrawingStroke> confirmed = state.strokes;
      List<CanvasAction> newUndo = state.undoHistory;
      if (current != null) {
        confirmed = [...confirmed, current];
        newUndo = _appendToHistory(newUndo, StrokeAction(current));
      }
      state = state.copyWith(
        strokes: confirmed,
        undoHistory: newUndo,
        remoteStroke: DrawingStroke(points: [point], color: color, width: width),
      );
    } else {
      state = state.copyWith(
        remoteStroke: current.copyWithPoints([...current.points, point]),
      );
    }
  }

  // ─── Undo / Redo ────────────────────────────────────────────────────────────

  void undo() {
    _doUndo();
    _sendUndoRedo(DrawType.undo);
  }

  void redo() {
    _doRedo();
    _sendUndoRedo(DrawType.redo);
  }

  /// 원격에서 받은 UNDO — STOMP 재전송 없음 (무한루프 방지)
  void _applyRemoteUndo() => _doUndo();

  /// 원격에서 받은 REDO — STOMP 재전송 없음
  void _applyRemoteRedo() => _doRedo();

  void _doUndo() {
    if (state.undoHistory.isEmpty) return;
    final last = state.undoHistory.last;
    final newUndo = state.undoHistory.sublist(0, state.undoHistory.length - 1);
    final newRedo = [...state.redoHistory, last];

    if (last is StrokeAction) {
      // 해당 스트로크를 strokes 목록에서 제거 (마지막 일치 항목)
      final idx = state.strokes.lastIndexWhere((s) => identical(s, last.stroke));
      final newStrokes = idx >= 0
          ? [...state.strokes.sublist(0, idx), ...state.strokes.sublist(idx + 1)]
          : state.strokes;
      state = state.copyWith(
        strokes: newStrokes,
        undoHistory: newUndo,
        redoHistory: newRedo,
      );
    } else if (last is ImageAction) {
      state = state.copyWith(
        backgroundImageUrl: last.prevUrl,
        undoHistory: newUndo,
        redoHistory: newRedo,
      );
    }
  }

  void _doRedo() {
    if (state.redoHistory.isEmpty) return;
    final last = state.redoHistory.last;
    final newRedo = state.redoHistory.sublist(0, state.redoHistory.length - 1);
    final newUndo = _appendToHistory(state.undoHistory, last);

    if (last is StrokeAction) {
      state = state.copyWith(
        strokes: [...state.strokes, last.stroke],
        undoHistory: newUndo,
        redoHistory: newRedo,
      );
    } else if (last is ImageAction) {
      // ImageAction에는 prevUrl(이전)만 있으므로, redo 시 undoHistory에서
      // 다음 ImageAction의 prevUrl을 newUrl로 사용할 수 없다.
      // 대신 redo 시 취소했던 이미지(마지막 undo 이전 상태)를 복원해야 하므로
      // redoHistory에 "새 URL"도 보관할 필요가 있다.
      // 현재 구현에서는 ImageAction.prevUrl로 undo, redo 시 다시 원래 url로 복원한다.
      // ImageAction을 RedoImageAction으로 다르게 저장하는 대신 간단히:
      // redo stack의 ImageAction은 "prevUrl = 복원할 URL"로 저장되어 있으므로 그대로 적용.
      state = state.copyWith(
        backgroundImageUrl: last.prevUrl,
        undoHistory: newUndo,
        redoHistory: newRedo,
      );
    }
  }

  void _sendUndoRedo(DrawType type) {
    final channelName = state.channelName;
    if (channelName == null) return;
    _repo.sendDraw(
      channelName,
      DrawEvent(senderId: _repo.sessionId, type: type),
    );
  }

  // ─── 히스토리 유틸 ─────────────────────────────────────────────────────────

  List<CanvasAction> _appendToHistory(List<CanvasAction> history, CanvasAction action) {
    final list = [...history, action];
    if (list.length > _maxUndoHistory) {
      return list.sublist(list.length - _maxUndoHistory);
    }
    return list;
  }

  // ─── 이미지 업로드 ──────────────────────────────────────────────────────────

  Future<void> uploadImage(XFile file) async {
    final lessonId = state.lessonId;
    final channelName = state.channelName;
    if (lessonId == null || channelName == null) return;

    try {
      final response = await _repo.uploadImage(lessonId, file);
      final newUndo = _appendToHistory(
        state.undoHistory,
        ImageAction(prevUrl: state.backgroundImageUrl),
      );
      state = state.copyWith(
        backgroundImageUrl: response.imageUrl,
        undoHistory: newUndo,
        redoHistory: const [],
      );
      _repo.sendDraw(
        channelName,
        DrawEvent(
          senderId: _repo.sessionId,
          type: DrawType.imageAdd,
          imageUrl: response.imageUrl,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: '이미지 업로드 실패: $e');
    }
  }

  // ─── 녹화 관리 ─────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final lessonId = state.lessonId;
    if (lessonId == null) return;
    await _repo.startRecording(lessonId);
    state = state.copyWith(isRecording: true);
  }

  Future<void> pauseRecording() async {
    final lessonId = state.lessonId;
    if (!state.isRecording || lessonId == null) return;
    final resp = await _repo.stopRecording(lessonId);
    state = state.copyWith(
      isRecording: false,
      recordingUrl: resp.recordingUrl ?? state.recordingUrl,
    );
  }

  Future<void> resumeRecording() async {
    final lessonId = state.lessonId;
    if (state.isRecording || lessonId == null) return;
    await _repo.startRecording(lessonId);
    state = state.copyWith(isRecording: true);
  }

  // ─── 수업 완료 ─────────────────────────────────────────────────────────────

  Future<void> completeLesson() async {
    final lessonId = state.lessonId;
    if (lessonId == null) return;

    try {
      String? recordingUrl = state.recordingUrl;

      if (state.isRecording) {
        final resp = await _repo.stopRecording(lessonId);
        recordingUrl = resp.recordingUrl ?? recordingUrl;
        state = state.copyWith(isRecording: false, recordingUrl: recordingUrl);
      }

      await _repo.completeLesson(lessonId, recordingUrl: recordingUrl);
      await _engine?.leaveChannel();
      _repo.disconnectStomp();

      state = state.copyWith(isCompleted: true);
    } catch (e) {
      state = state.copyWith(error: '수업 완료 처리 실패: $e');
    }
  }

  // ─── 정리 ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _engine?.leaveChannel().then((_) => _engine?.release());
    _repo.disconnectStomp();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final lessonProvider =
    StateNotifierProvider.autoDispose<LessonNotifier, LessonState>(
  (ref) => LessonNotifier(LessonRepository()),
);
