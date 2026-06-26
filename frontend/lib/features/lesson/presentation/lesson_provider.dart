import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/simulator_detector.dart';
import '../data/lesson_repository.dart';
import '../domain/lesson_model.dart';

// ─── 상수 ─────────────────────────────────────────────────────────────────────

const _eraserWidth = 16.0;
const _maxUndoHistory = 50;
const _kDefaultImageWidth = 400.0;
const _kDefaultImageHeight = 300.0;

// ─── State ────────────────────────────────────────────────────────────────────

@immutable
class LessonState {
  final String? channelName;
  final String? token;
  final String? appId;
  final int? lessonId;
  final int? studentId;
  final int? tutorId;
  final int? uid;
  final bool isTutor;

  final bool isInChannel;
  final int? remoteUid;
  final bool localCameraEnabled;
  final bool remoteCameraEnabled;
  final double remoteScale;
  final double remoteOffsetX;
  final double remoteOffsetY;

  final Color currentPenColor;
  final bool isEraserMode;

  final bool isMicEnabled;
  final bool remoteMicEnabled;
  final double? remoteCameraRatio;

  final bool isRecording;
  final String? recordingUrl;

  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final DrawingStroke? remoteStroke;

  final List<ImageItem> backgroundImages;
  final int? selectedImageIndex;

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
    this.studentId,
    this.tutorId,
    this.uid,
    this.isTutor = false,
    this.isInChannel = false,
    this.remoteUid,
    this.localCameraEnabled = false,
    this.remoteCameraEnabled = false,
    this.remoteScale = 1.0,
    this.remoteOffsetX = 0.0,
    this.remoteOffsetY = 0.0,
    this.currentPenColor = Colors.black,
    this.isEraserMode = false,
    this.isMicEnabled = true,
    this.remoteMicEnabled = true,
    this.remoteCameraRatio,
    this.isRecording = false,
    this.recordingUrl,
    this.strokes = const [],
    this.currentStroke,
    this.remoteStroke,
    this.backgroundImages = const [],
    this.selectedImageIndex,
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
    int? studentId,
    int? tutorId,
    int? uid,
    bool? isTutor,
    bool? isInChannel,
    Object? remoteUid = _sentinel,
    bool? localCameraEnabled,
    bool? remoteCameraEnabled,
    double? remoteScale,
    double? remoteOffsetX,
    double? remoteOffsetY,
    Color? currentPenColor,
    bool? isEraserMode,
    bool? isMicEnabled,
    bool? remoteMicEnabled,
    Object? remoteCameraRatio = _sentinel,
    bool? isRecording,
    Object? recordingUrl = _sentinel,
    List<DrawingStroke>? strokes,
    Object? currentStroke = _sentinel,
    Object? remoteStroke = _sentinel,
    List<ImageItem>? backgroundImages,
    Object? selectedImageIndex = _sentinel,
    List<CanvasAction>? undoHistory,
    List<CanvasAction>? redoHistory,
    bool? isLoading,
    bool? isCompleted,
    Object? error = _sentinel,
  }) {
    return LessonState(
      channelName: channelName ?? this.channelName,
      studentId: studentId ?? this.studentId,
      tutorId: tutorId ?? this.tutorId,
      token: token ?? this.token,
      appId: appId ?? this.appId,
      lessonId: lessonId ?? this.lessonId,
      uid: uid ?? this.uid,
      isTutor: isTutor ?? this.isTutor,
      isInChannel: isInChannel ?? this.isInChannel,
      remoteUid: remoteUid == _sentinel ? this.remoteUid : remoteUid as int?,
      localCameraEnabled: localCameraEnabled ?? this.localCameraEnabled,
      remoteCameraEnabled: remoteCameraEnabled ?? this.remoteCameraEnabled,
      remoteScale: remoteScale ?? this.remoteScale,
      remoteOffsetX: remoteOffsetX ?? this.remoteOffsetX,
      remoteOffsetY: remoteOffsetY ?? this.remoteOffsetY,
      currentPenColor: currentPenColor ?? this.currentPenColor,
      isEraserMode: isEraserMode ?? this.isEraserMode,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      remoteMicEnabled: remoteMicEnabled ?? this.remoteMicEnabled,
      remoteCameraRatio: remoteCameraRatio == _sentinel ? this.remoteCameraRatio : remoteCameraRatio as double?,
      isRecording: isRecording ?? this.isRecording,
      recordingUrl:
          recordingUrl == _sentinel ? this.recordingUrl : recordingUrl as String?,
      strokes: strokes ?? this.strokes,
      currentStroke:
          currentStroke == _sentinel ? this.currentStroke : currentStroke as DrawingStroke?,
      remoteStroke:
          remoteStroke == _sentinel ? this.remoteStroke : remoteStroke as DrawingStroke?,
      backgroundImages: backgroundImages ?? this.backgroundImages,
      selectedImageIndex: selectedImageIndex == _sentinel
          ? this.selectedImageIndex
          : selectedImageIndex as int?,
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
  String? _currentStrokeId;
  final Map<String, DrawingStroke> _deletedStrokes = {};

  LessonNotifier(this._repo) : super(const LessonState());

  RtcEngine? get engine => _engine;

  // ─── 초기화 ────────────────────────────────────────────────────────────────

  Future<void> initialize(
    String channelName,
    int uid,
    bool isTutor, {
    List<String> imageUrls = const [],
  }) async {
    state = state.copyWith(
      isLoading: true,
      channelName: channelName,
      uid: uid,
      isTutor: isTutor,
      localCameraEnabled: false,
    );

    try {
      final agoraUid = isTutor ? uid : uid + 10000;

      final tokenResp = await _repo.fetchToken(
        channelName: channelName,
        uid: agoraUid.toString(),
        role: 'PUBLISHER',
      );
      if (!mounted) return; // 비동기 도중 강의실 이탈로 dispose되면 중단

      state = state.copyWith(
        token: tokenResp.token,
        appId: tokenResp.appId,
        lessonId: tokenResp.lessonId,
        studentId: tokenResp.studentId,
        tutorId: tokenResp.tutorId,
      );

      if (!kIsWeb) {
        // iOS 시뮬레이터엔 카메라/마이크 하드웨어가 없어 권한을 받을 수 없다.
        // 수업은 오디오 전용이고 채널 입장(join)은 네트워크라 권한 없이도 되므로,
        // 시뮬에선 권한 게이트를 통째로 건너뛰고 바로 입장한다(테스트 목적).
        // 실기기는 기존대로 카메라+마이크 권한을 요구한다.
        final isSim = await isIosSimulator();
        if (!mounted) return;
        if (!isSim) {
          final statuses = await [
            Permission.camera,
            Permission.microphone,
          ].request();
          if (!mounted) return;
          if (statuses[Permission.camera] != PermissionStatus.granted ||
              statuses[Permission.microphone] != PermissionStatus.granted) {
            state = state.copyWith(
              isLoading: false,
              error: '카메라/마이크 권한이 필요합니다',
            );
            return;
          }
        } else {
          debugPrint('[Lesson] iOS 시뮬레이터 → 권한 게이트 스킵, 바로 입장');
        }

        _engine = createAgoraRtcEngine();
        await _engine!.initialize(RtcEngineContext(appId: tokenResp.appId));

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (connection, elapsed) {
              debugPrint('[Agora] 채널 입장 성공: ${connection.channelId}');
              state = state.copyWith(isInChannel: true);
            },
            // join 실패가 조용히 묻히지 않도록 에러를 로그로 노출(시간 안 가는 원인 진단용).
            onError: (err, msg) {
              debugPrint('[Agora] onError: $err / $msg');
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

        await _engine!.setAudioProfile(
          profile: AudioProfileType.audioProfileDefault,
          scenario: AudioScenarioType.audioScenarioDefault,
        );
        await _engine!.enableAudio();
        await _engine!.muteLocalAudioStream(false);
        await _engine!.enableVideo();
        await _engine!.enableLocalVideo(false);

        await _engine!.joinChannel(
          token: tokenResp.token,
          channelId: channelName,
          uid: agoraUid,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileCommunication,
            publishMicrophoneTrack: true,
            publishCameraTrack: false,
          ),
        );
      }

      _repo.connectStomp(channelName, _onRemoteDrawEvent);

      if (!kIsWeb && isTutor) {
        await _startRecording();
      }

      if (!mounted) return; // Agora 입장/녹화 시작 동안 이탈했으면 중단
      state = state.copyWith(isLoading: false);

      if (imageUrls.isNotEmpty) {
        final images = imageUrls
            .map((url) => ImageItem(
                  url: url,
                  width: _kDefaultImageWidth,
                  height: _kDefaultImageHeight,
                ))
            .toList();
        state = state.copyWith(backgroundImages: images);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ─── 카메라 토글 ────────────────────────────────────────────────────────────

  Future<void> toggleCamera() async {
    if (_engine == null) return;
    final next = !state.localCameraEnabled;
    await _engine!.enableLocalVideo(next);
    await _engine!.updateChannelMediaOptions(
      ChannelMediaOptions(publishCameraTrack: next),
    );
    if (next) await _engine!.startPreview();
    state = state.copyWith(localCameraEnabled: next);
    final channelName = state.channelName;
    if (channelName != null) {
      _repo.sendDraw(
        channelName,
        DrawEvent(
          senderId: _repo.sessionId,
          type: next ? DrawType.cameraOn : DrawType.cameraOff,
        ),
      );
    }
  }

  // ─── 마이크 토글 ────────────────────────────────────────────────────────────

  Future<void> toggleMic() async {
    final next = !state.isMicEnabled;
    if (!kIsWeb) {
      await _engine?.muteLocalAudioStream(!next);
    }
    state = state.copyWith(isMicEnabled: next);
    final channelName = state.channelName;
    if (channelName != null) {
      _repo.sendDraw(
        channelName,
        DrawEvent(
          senderId: _repo.sessionId,
          type: next ? DrawType.micOn : DrawType.micOff,
        ),
      );
    }
  }

  // ─── 줌 동기화 ─────────────────────────────────────────────────────────────

  void sendZoom(double scale, Offset offset) {
    final channelName = state.channelName;
    if (channelName == null) return;
    _repo.sendDraw(
      channelName,
      DrawEvent(
        senderId: _repo.sessionId,
        type: DrawType.zoom,
        scale: scale,
        offsetX: offset.dx,
        offsetY: offset.dy,
      ),
    );
  }

  // ─── 카메라 비율 동기화 ─────────────────────────────────────────────────────

  void sendCameraRatio(double ratio) {
    final channelName = state.channelName;
    if (channelName == null) return;
    _repo.sendDraw(
      channelName,
      DrawEvent(
        senderId: _repo.sessionId,
        type: DrawType.cameraRatio,
        cameraRatio: ratio,
      ),
    );
  }

  // ─── 이미지 편집 ────────────────────────────────────────────────────────────

  void selectImage(int? index) {
    state = state.copyWith(selectedImageIndex: index);
  }

  void updateImageBounds({
    required int index,
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    if (index < 0 || index >= state.backgroundImages.length) return;
    final images = List<ImageItem>.from(state.backgroundImages);
    images[index] = images[index].copyWith(x: x, y: y, width: width, height: height);
    state = state.copyWith(backgroundImages: images);
  }

  void sendImageMove(int index) {
    final channelName = state.channelName;
    if (channelName == null || index >= state.backgroundImages.length) return;
    final image = state.backgroundImages[index];
    _repo.sendDraw(
      channelName,
      DrawEvent(
        senderId: _repo.sessionId,
        type: DrawType.imageMove,
        index: index,
        x: image.x,
        y: image.y,
        width: image.width,
        height: image.height,
      ),
    );
  }

  // ─── 이미지 삭제 ────────────────────────────────────────────────────────────

  void deleteImage(int index) {
    if (index < 0 || index >= state.backgroundImages.length) return;
    final images = List<ImageItem>.from(state.backgroundImages)..removeAt(index);
    state = state.copyWith(
      backgroundImages: images,
      selectedImageIndex: null,
    );
    final channelName = state.channelName;
    if (channelName != null) {
      _repo.sendDraw(
        channelName,
        DrawEvent(
          senderId: _repo.sessionId,
          type: DrawType.imageDelete,
          index: index,
        ),
      );
    }
  }

  // ─── 펜 도구 ───────────────────────────────────────────────────────────────

  void setPenColor(Color color) {
    state = state.copyWith(
      currentPenColor: color,
      isEraserMode: false,
      selectedImageIndex: null,
    );
  }

  void toggleEraser() {
    state = state.copyWith(
      isEraserMode: !state.isEraserMode,
      selectedImageIndex: null,
    );
  }

  // ─── 화이트보드 드로잉 ──────────────────────────────────────────────────────

  void onPanStart(Offset position) {
    final isEraser = state.isEraserMode;
    final color = isEraser ? Colors.white : state.currentPenColor;
    final width = isEraser ? _eraserWidth : AppConstants.defaultPenWidth;
    final type = isEraser ? DrawType.erase : DrawType.draw;

    _currentStrokeId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

    final stroke = DrawingStroke(
      id: _currentStrokeId!,
      points: [position],
      color: color,
      width: width,
      isEraser: isEraser,
    );
    state = state.copyWith(currentStroke: stroke);
    _sendDrawPoint(position, type: type, isStart: true, strokeId: _currentStrokeId);
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
      redoHistory: const [],
    );
  }

  void cancelCurrentStroke() {
    if (state.currentStroke == null) return;
    state = state.copyWith(currentStroke: null);
  }

  void _sendDrawPoint(
    Offset position, {
    DrawType type = DrawType.draw,
    bool isStart = false,
    String? strokeId,
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
        strokeId: strokeId,
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
          backgroundImages: const [],
          selectedImageIndex: null,
          undoHistory: const [],
          redoHistory: const [],
        );
      case DrawType.imageAdd:
        if (event.imageUrl != null) {
          final newImage = ImageItem(
            url: event.imageUrl!,
            x: event.x ?? 0.0,
            y: event.y ?? 0.0,
            width: event.width ?? _kDefaultImageWidth,
            height: event.height ?? _kDefaultImageHeight,
          );
          state = state.copyWith(
            backgroundImages: [...state.backgroundImages, newImage],
          );
        }
      case DrawType.imageMove:
        final idx = event.index;
        if (idx == null || event.width == null || idx >= state.backgroundImages.length) return;
        final images = List<ImageItem>.from(state.backgroundImages);
        images[idx] = images[idx].copyWith(
          x: event.x,
          y: event.y,
          width: event.width,
          height: event.height,
        );
        state = state.copyWith(backgroundImages: images);
      case DrawType.imageDelete:
        final delIdx = event.index;
        if (delIdx == null || delIdx >= state.backgroundImages.length) return;
        final imgs = List<ImageItem>.from(state.backgroundImages)..removeAt(delIdx);
        state = state.copyWith(backgroundImages: imgs, selectedImageIndex: null);
      case DrawType.undo:
        _applyRemoteUndo(event);
      case DrawType.redo:
        _applyRemoteRedo(event);
      case DrawType.zoom:
        if (event.scale != null) {
          state = state.copyWith(
            remoteScale: event.scale!.clamp(0.5, 4.0),
            remoteOffsetX: event.offsetX ?? 0.0,
            remoteOffsetY: event.offsetY ?? 0.0,
          );
        }
      case DrawType.cameraOn:
        state = state.copyWith(remoteCameraEnabled: true);
      case DrawType.cameraOff:
        state = state.copyWith(remoteCameraEnabled: false);
      case DrawType.micOn:
        state = state.copyWith(remoteMicEnabled: true);
      case DrawType.micOff:
        state = state.copyWith(remoteMicEnabled: false);
      case DrawType.cameraRatio:
        if (event.cameraRatio != null) {
          state = state.copyWith(remoteCameraRatio: event.cameraRatio!.clamp(0.1, 0.5));
        }
      case DrawType.lessonEnd:
        _applyRemoteComplete();
    }
  }

  void _applyRemoteComplete() {
    _repo.disconnectStomp();
    _engine?.leaveChannel();
    state = state.copyWith(isCompleted: true);
  }

  void _applyRemoteDrawPoint(DrawEvent event) {
    if (event.x == null || event.y == null) return;
    final point = Offset(event.x!, event.y!);
    final color = colorFromHex(event.color ?? AppConstants.defaultPenColor);
    final width = event.strokeWidth ?? AppConstants.defaultPenWidth;

    final current = state.remoteStroke;
    final forceNew = event.isStart == true;

    if (current == null || forceNew || current.color != color || current.width != width) {
      List<DrawingStroke> confirmed = state.strokes;
      if (current != null) {
        confirmed = [...confirmed, current];
      }
      state = state.copyWith(
        strokes: confirmed,
        remoteStroke: DrawingStroke(
          id: event.strokeId ?? '',
          points: [point],
          color: color,
          width: width,
          isEraser: event.type == DrawType.erase,
        ),
      );
    } else {
      state = state.copyWith(
        remoteStroke: current.copyWithPoints([...current.points, point]),
      );
    }
  }

  // ─── Undo / Redo ────────────────────────────────────────────────────────────

  void undo() {
    if (state.undoHistory.isEmpty) return;
    final last = state.undoHistory.last;
    _doUndo();
    final strokeId = last is StrokeAction ? last.stroke.id : null;
    _sendUndoRedo(DrawType.undo, strokeId: strokeId);
  }

  void redo() {
    if (state.redoHistory.isEmpty) return;
    final last = state.redoHistory.last;
    _doRedo();
    final strokeId = last is StrokeAction ? last.stroke.id : null;
    _sendUndoRedo(DrawType.redo, strokeId: strokeId);
  }

  void _applyRemoteUndo(DrawEvent event) {
    final sid = event.strokeId;
    if (sid != null && sid.isNotEmpty) {
      final inStrokes = state.strokes.where((s) => s.id == sid);
      if (inStrokes.isNotEmpty) _deletedStrokes[sid] = inStrokes.first;
      if (state.remoteStroke?.id == sid) {
        _deletedStrokes[sid] = state.remoteStroke!;
      }
      final newStrokes = state.strokes.where((s) => s.id != sid).toList();
      final newRemote =
          (state.remoteStroke?.id == sid) ? null : state.remoteStroke;
      final newUndo = state.undoHistory
          .where((a) => !(a is StrokeAction && a.stroke.id == sid))
          .toList();
      state = state.copyWith(
        strokes: newStrokes,
        remoteStroke: newRemote,
        undoHistory: newUndo,
      );
    } else {
      _doUndo();
    }
  }

  void _applyRemoteRedo(DrawEvent event) {
    final sid = event.strokeId;
    if (sid != null && sid.isNotEmpty) {
      if (_deletedStrokes.containsKey(sid)) {
        final stroke = _deletedStrokes.remove(sid)!;
        state = state.copyWith(strokes: [...state.strokes, stroke]);
        return;
      }
      final idx = state.redoHistory
          .indexWhere((a) => a is StrokeAction && a.stroke.id == sid);
      if (idx >= 0) {
        final action = state.redoHistory[idx] as StrokeAction;
        final newRedo = [...state.redoHistory]..removeAt(idx);
        state = state.copyWith(
          strokes: [...state.strokes, action.stroke],
          redoHistory: newRedo,
        );
        return;
      }
    }
  }

  void _doUndo() {
    if (state.undoHistory.isEmpty) return;
    final last = state.undoHistory.last;
    final newUndo = state.undoHistory.sublist(0, state.undoHistory.length - 1);

    if (last is StrokeAction) {
      final newRedo = [...state.redoHistory, last];
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
      // redoHistory에는 현재 상태를 담은 새 액션 push (역방향으로 사용하기 위해)
      final redoAction = ImageAction(prevImages: state.backgroundImages);
      final newRedo = [...state.redoHistory, redoAction];
      state = state.copyWith(
        backgroundImages: last.prevImages,
        selectedImageIndex: null,
        undoHistory: newUndo,
        redoHistory: newRedo,
      );
    }
  }

  void _doRedo() {
    if (state.redoHistory.isEmpty) return;
    final last = state.redoHistory.last;
    final newRedo = state.redoHistory.sublist(0, state.redoHistory.length - 1);

    if (last is StrokeAction) {
      final newUndo = _appendToHistory(state.undoHistory, last);
      state = state.copyWith(
        strokes: [...state.strokes, last.stroke],
        undoHistory: newUndo,
        redoHistory: newRedo,
      );
    } else if (last is ImageAction) {
      final undoAction = ImageAction(prevImages: state.backgroundImages);
      final newUndo = _appendToHistory(state.undoHistory, undoAction);
      state = state.copyWith(
        backgroundImages: last.prevImages,
        selectedImageIndex: null,
        undoHistory: newUndo,
        redoHistory: newRedo,
      );
    }
  }

  void _sendUndoRedo(DrawType type, {String? strokeId}) {
    final channelName = state.channelName;
    if (channelName == null) return;
    _repo.sendDraw(
      channelName,
      DrawEvent(senderId: _repo.sessionId, type: type, strokeId: strokeId),
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
    debugPrint('[업로드] lessonId=$lessonId, channelName=$channelName');
    if (lessonId == null || channelName == null) {
      debugPrint('[업로드] lessonId 또는 channelName이 null이라 return');
      return;
    }

    try {
      final response = await _repo.uploadImage(lessonId, file);
      final newImage = ImageItem(
        url: response.imageUrl,
        width: _kDefaultImageWidth,
        height: _kDefaultImageHeight,
      );
      final prevImages = state.backgroundImages;
      final newImages = [...prevImages, newImage];
      final newUndo = _appendToHistory(
        state.undoHistory,
        ImageAction(prevImages: prevImages),
      );
      state = state.copyWith(
        backgroundImages: newImages,
        selectedImageIndex: newImages.length - 1,
        undoHistory: newUndo,
        redoHistory: const [],
      );
      _repo.sendDraw(
        channelName,
        DrawEvent(
          senderId: _repo.sessionId,
          type: DrawType.imageAdd,
          imageUrl: response.imageUrl,
          x: 0.0,
          y: 0.0,
          width: _kDefaultImageWidth,
          height: _kDefaultImageHeight,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: '이미지 업로드 실패: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
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
        try {
          final resp = await _repo.stopRecording(lessonId);
          recordingUrl = resp.recordingUrl ?? recordingUrl;
        } catch (e) {
          debugPrint('녹화 중지 실패 (수업 완료는 계속 진행): $e');
        }
        state = state.copyWith(isRecording: false, recordingUrl: recordingUrl);
      }

      await _repo.completeLesson(lessonId, recordingUrl: recordingUrl);

      final channelName = state.channelName;
      if (channelName != null) {
        _repo.sendDraw(
          channelName,
          DrawEvent(
            senderId: _repo.sessionId,
            type: DrawType.lessonEnd,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 200));
      }

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
