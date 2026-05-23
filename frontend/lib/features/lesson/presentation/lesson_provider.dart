import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../data/lesson_repository.dart';
import '../domain/lesson_model.dart';

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

  final bool isRecording;
  final String? recordingUrl;

  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final DrawingStroke? remoteStroke;
  final String? backgroundImageUrl;

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
    this.isRecording = false,
    this.recordingUrl,
    this.strokes = const [],
    this.currentStroke,
    this.remoteStroke,
    this.backgroundImageUrl,
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
    bool? isRecording,
    Object? recordingUrl = _sentinel,
    List<DrawingStroke>? strokes,
    Object? currentStroke = _sentinel,
    Object? remoteStroke = _sentinel,
    Object? backgroundImageUrl = _sentinel,
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
      if (isTutor) {
        await _engine!.enableVideo();
      } else {
        // 학생: 비디오 캡처 비활성화, 마이크만 활성화
        await _engine!.enableLocalVideo(false);
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
    await _engine!.muteLocalVideoStream(!next);
    state = state.copyWith(localCameraEnabled: next);
  }

  // ─── 화이트보드 드로잉 ──────────────────────────────────────────────────────

  void onPanStart(Offset position) {
    final stroke = DrawingStroke(
      points: [position],
      color: colorFromHex(AppConstants.defaultPenColor),
      width: AppConstants.defaultPenWidth,
    );
    state = state.copyWith(currentStroke: stroke);
    _sendDraw(position);
  }

  void onPanUpdate(Offset position) {
    final current = state.currentStroke;
    if (current == null) return;
    state = state.copyWith(
      currentStroke: current.copyWithPoints([...current.points, position]),
    );
    _sendDraw(position);
  }

  void onPanEnd() {
    final current = state.currentStroke;
    if (current == null) return;
    state = state.copyWith(
      strokes: [...state.strokes, current],
      currentStroke: null,
    );
  }

  void _sendDraw(Offset position) {
    final channelName = state.channelName;
    if (channelName == null) return;
    _repo.sendDraw(
      channelName,
      DrawEvent(
        senderId: _repo.sessionId,
        type: DrawType.draw,
        x: position.dx,
        y: position.dy,
        color: AppConstants.defaultPenColor,
        strokeWidth: AppConstants.defaultPenWidth,
      ),
    );
  }

  void _onRemoteDrawEvent(DrawEvent event) {
    switch (event.type) {
      case DrawType.draw:
        _applyRemoteDrawPoint(event);
      case DrawType.clear:
        state = state.copyWith(
          strokes: [],
          remoteStroke: null,
          backgroundImageUrl: null,
        );
      case DrawType.imageAdd:
        if (event.imageUrl != null) {
          state = state.copyWith(backgroundImageUrl: event.imageUrl);
        }
      case DrawType.erase:
        break;
    }
  }

  void _applyRemoteDrawPoint(DrawEvent event) {
    if (event.x == null || event.y == null) return;
    final point = Offset(event.x!, event.y!);
    final color = colorFromHex(event.color ?? AppConstants.defaultPenColor);
    final width = event.strokeWidth ?? AppConstants.defaultPenWidth;

    final current = state.remoteStroke;
    if (current == null ||
        current.color != color ||
        current.width != width) {
      // 색/굵기가 바뀌면 이전 원격 스트로크 확정 후 새 스트로크 시작
      final confirmed = current != null
          ? [...state.strokes, current]
          : state.strokes;
      state = state.copyWith(
        strokes: confirmed,
        remoteStroke: DrawingStroke(points: [point], color: color, width: width),
      );
    } else {
      state = state.copyWith(
        remoteStroke: current.copyWithPoints([...current.points, point]),
      );
    }
  }

  // ─── 이미지 업로드 ──────────────────────────────────────────────────────────

  Future<void> uploadImage(XFile file) async {
    final lessonId = state.lessonId;
    final channelName = state.channelName;
    if (lessonId == null || channelName == null) return;

    try {
      final response = await _repo.uploadImage(lessonId, file);
      state = state.copyWith(backgroundImageUrl: response.imageUrl);
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
