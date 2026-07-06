import 'dart:async';
import 'dart:ui' as ui;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_error.dart';
import '../../student/providers/payment_provider.dart';
import '../data/lesson_repository.dart';
import '../domain/lesson_model.dart';

// ─── 상수 ─────────────────────────────────────────────────────────────────────

const _eraserWidth = 16.0;
const _maxUndoHistory = 50;
const _kDefaultImageWidth = 400.0;
const _kDefaultImageHeight = 300.0;

/// 녹화봇(recorder.html)의 고정 RTC uid — recorder.html의 RECORDER_RTC_UID와 동일.
/// 녹화봇은 같은 채널에 들어오지만 비디오를 publish하지 않으므로, 원격 유저 추적에서
/// 제외해 강사 캠 uid를 덮어쓰지 않게 한다. (recorder.html은 절대 건드리지 않음)
const kRecorderRtcUid = 1234567;

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
  final Ref _ref; // 코인 hold/차감 후 잔액 표시 갱신용
  RtcEngine? _engine;
  String? _currentStrokeId;
  final Map<String, DrawingStroke> _deletedStrokes = {};

  /// 녹화 프레임 방향 결정 — 강사 기기(앱 창)의 화면 방향 기준.
  /// 화이트보드 영역 비율은 카메라 패널 ON/OFF로 흔들리므로, 카메라와 무관하게
  /// 안정적인 창 방향(physicalSize)으로 판정한다. Notifier에는 BuildContext가
  /// 없으므로 전역 싱글턴 platformDispatcher에서 직접 읽는다(프레임워크의
  /// MediaQuery.orientation과 동일한 width>height 판정식).
  /// 가로(w>h)면 'landscape', 그 외(정사각·세로·이상값·예외)는 'portrait' 폴백.
  String _recordingOrientation() {
    try {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return 'portrait';
      final size = views.first.physicalSize;
      final w = size.width, h = size.height;
      if (w.isFinite && h.isFinite && w > 0 && h > 0 && w > h) {
        return 'landscape';
      }
      return 'portrait';
    } catch (_) {
      return 'portrait';
    }
  }

  LessonNotifier(this._repo, this._ref) : super(const LessonState());

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

      if (!mounted) return;
      state = state.copyWith(
        token: tokenResp.token,
        appId: tokenResp.appId,
        lessonId: tokenResp.lessonId,
        studentId: tokenResp.studentId,
        tutorId: tokenResp.tutorId,
      );

      // 과금 강의 시작(학생만): 기본 30분(50코인) 홀드 + ACTIVE 전환.
      // 부족하면 백엔드가 "코인이 부족합니다" 400 → error로 노출(충전 유도). 강사는 과금 안 함.
      if (!isTutor &&
          tokenResp.studentId != null &&
          tokenResp.tutorId != null) {
        try {
          await _repo.startLesson(
            lessonId: tokenResp.lessonId,
            studentId: tokenResp.studentId!,
            tutorId: tokenResp.tutorId!,
          );
        } catch (e) {
          if (!mounted) return;
          state = state.copyWith(
            isLoading: false,
            error: apiErrorMessage(e,
                fallback: '강의 시작에 실패했어요. 코인을 확인해 주세요.'),
          );
          return;
        }
        if (!mounted) return;
        // 50코인 hold 됨 → 가용 잔액(availableBalance) 표시 즉시 갱신.
        _ref.invalidate(coinBalanceProvider);
      }

      if (!kIsWeb) {
        // 카메라·마이크 권한은 입장 상류(매칭 "수락" 시점)에서 게이트한다.
        // 여기선 권한을 재확인하지 않는다 — 미허용이어도 오류방을 띄우지 않고
        // 그대로 진행(권한 없으면 Agora가 degraded로 동작). 오류방 재발 방지.
        _engine = createAgoraRtcEngine();
        await _engine!.initialize(RtcEngineContext(appId: tokenResp.appId));

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (connection, elapsed) {
              debugPrint('[Agora] 채널 입장 성공: ${connection.channelId}');
              state = state.copyWith(isInChannel: true);
              // 화이트보드 화면은 Agora Web Page Recording(recorder.html)이 녹화한다.
              // 강사일 때만, recorder가 STOMP 연결되고 그림 준비될 시간을 준 뒤(~5초)
              // 녹화를 시작한다. (Agora도 web 녹화 시작에 수 초 소요)
              if (isTutor) {
                Future.delayed(const Duration(seconds: 5), () {
                  _startRecording();
                });
              }
            },
            // join 실패가 조용히 묻히지 않도록 에러를 로그로 노출(시간 안 가는 원인 진단용).
            onError: (err, msg) {
              debugPrint('[Agora] onError: $err / $msg');
            },
            onUserJoined: (connection, remoteUid, elapsed) {
              // 녹화봇(비디오 미발행)은 무시 — 강사 캠 uid를 덮어쓰지 않게 한다.
              if (remoteUid == kRecorderRtcUid) return;
              state = state.copyWith(remoteUid: remoteUid);
            },
            onUserOffline: (connection, remoteUid, reason) {
              if (remoteUid == kRecorderRtcUid) return;
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
        // 비디오 모듈만 켠다(원격 영상 구독/렌더용). 로컬 카메라 캡처는 입장 시 완전 OFF —
        // 강사가 toggleCamera()로 켤 때 enableLocalVideo(true)로 처음 활성화된다.
        // (카메라 권한은 위 게이트에서 이미 받아둬 토글 시 팝업 없이 매끄럽게 켜짐)
        await _engine!.enableLocalVideo(false);

        await _engine!.joinChannel(
          token: tokenResp.token,
          channelId: channelName,
          uid: agoraUid,
          options: ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileCommunication,
            publishMicrophoneTrack: true,
            publishCameraTrack: false,
          ),
        );
        if (!mounted) return;
      }

      await _repo.connectStomp(channelName, _onRemoteDrawEvent);

      // 화이트보드 비디오/녹화는 Agora Web Page Recording(recorder.html)이 담당.

      if (!mounted) return; // Agora 입장 동안 이탈했으면 중단
      state = state.copyWith(isLoading: false);

      if (imageUrls.isNotEmpty) {
        final images = <ImageItem>[];
        for (var i = 0; i < imageUrls.length; i++) {
          final resolvedUrl = ApiConstants.resolveImageUrl(imageUrls[i]);
          double imgWidth = 400.0;
          double imgHeight = 400.0;
          try {
            final completer = Completer<ui.Image>();
            final stream =
                NetworkImage(resolvedUrl).resolve(const ImageConfiguration());
            late ImageStreamListener listener;
            listener = ImageStreamListener(
              (info, _) {
                completer.complete(info.image);
                stream.removeListener(listener);
              },
              onError: (_, _) {
                completer.completeError('load failed');
                stream.removeListener(listener);
              },
            );
            stream.addListener(listener);
            final loaded = await completer.future;
            final origW = loaded.width.toDouble();
            final origH = loaded.height.toDouble();
            if (origW > 0) {
              imgWidth = 400.0;
              imgHeight = 400.0 * origH / origW;
            }
          } catch (_) {}
          images.add(ImageItem(
            url: resolvedUrl,
            x: i * 440.0 + 30.0,
            y: 30.0,
            width: imgWidth,
            height: imgHeight,
          ));
        }
        state = state.copyWith(backgroundImages: images);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ─── 카메라 토글 ────────────────────────────────────────────────────────────
  // 입장 시엔 OFF(join 옵션 publishCameraTrack:false). 강사가 토글로 켜고 끈다.
  // 표준 카메라(publishCameraTrack)만 사용 — pushVideoFrame/커스텀 비디오 소스 부활 금지.
  // 녹화(recorder.html)는 비디오를 구독/렌더하지 않으므로 캠은 녹화에 안 들어간다.

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

  // ─── 뷰포트 크기 전송 (Agora Web Page Recording 좌표 정합용) ─────────────────

  /// 강사 화이트보드 영역의 실제 크기(논리픽셀)를 전송.
  /// recorder.html이 이 값으로 녹화 프레임에 fit 스케일(레터박스)을 적용한다.
  void sendViewport(double w, double h) {
    final channelName = state.channelName;
    if (channelName == null) return;
    _repo.sendDraw(
      channelName,
      DrawEvent(
        senderId: _repo.sessionId,
        type: DrawType.viewport,
        width: w,
        height: h,
      ),
    );
  }

  /// 현재 이미지 목록 전체를 스냅샷으로 전송 (recorder가 board.images를 replace).
  /// 초기 이미지 누락 + index 어긋남을 한 번에 해결. 강사만 주기 호출한다.
  void sendImageSync() {
    final channelName = state.channelName;
    if (channelName == null) return;
    final items = state.backgroundImages
        .map((img) => ImageSyncItem(
              url: img.url,
              x: img.x,
              y: img.y,
              width: img.width,
              height: img.height,
            ))
        .toList();
    _repo.sendDraw(
      channelName,
      DrawEvent(
        senderId: _repo.sessionId,
        type: DrawType.imageSync,
        images: items,
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
      case DrawType.viewport:
      case DrawType.imageSync:
        // 강사→recorder 전용. 학생 앱에서는 무시한다.
        break;
      case DrawType.lessonEnd:
        _applyRemoteComplete();
    }
  }

  Future<void> _applyRemoteComplete() async {
    _repo.disconnectStomp();
    _engine?.leaveChannel();
    // 상대(주로 강사)가 종료한 경우에도, 학생 쪽에서 백엔드 완료를 한 번 더 보장한다(멱등).
    // 끝낸 쪽의 complete가 누락/실패하면 강의가 ACTIVE로 남아 리뷰(COMPLETED 전용)가 막히므로.
    final lessonId = state.lessonId;
    if (lessonId != null) {
      try {
        await _repo.completeLesson(lessonId);
      } catch (_) {
        // 이미 완료됐거나 일시 실패여도 리뷰 화면 진입은 진행(다음에 재시도 가능)
      }
    }
    if (!mounted) return;
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

  // Web Page Recording 모드 녹화 시작 — 강사 채널 입장 후 호출.
  Future<void> _startRecording() async {
    debugPrint('[녹화] _startRecording() 호출됨, lessonId=${state.lessonId}');
    final lessonId = state.lessonId;
    if (lessonId == null) return;
    await _repo.startRecording(lessonId, orientation: _recordingOrientation());
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
    // resume은 새 클라우드 녹화를 start하므로 현재 화이트보드 방향을 반영한다.
    await _repo.startRecording(lessonId, orientation: _recordingOrientation());
    state = state.copyWith(isRecording: true);
  }

  // ─── 강의 연장 ─────────────────────────────────────────────────────────────

  /// 강의 연장(학생). 10/20/30분 추가 hold.
  /// - 성공: 코인 추가 hold → 잔액 표시 갱신, extended=true 반환
  /// - 잔액 부족: hold 없이 extended=false + shortfallCoin 반환(UI가 충전 유도 후 재시도)
  /// 허용 단위 외/네트워크 오류는 예외를 던진다(호출부가 메시지 노출).
  Future<ExtendLessonResult> extendLesson(int minutes) async {
    final lessonId = state.lessonId;
    final studentId = state.studentId;
    if (lessonId == null || studentId == null) {
      throw StateError('강의 정보가 없어 연장할 수 없어요.');
    }
    final result = await _repo.extendLesson(
      lessonId: lessonId,
      studentId: studentId,
      minutes: minutes,
    );
    if (result.extended) {
      _ref.invalidate(coinBalanceProvider); // 추가 hold 반영
    }
    return result;
  }

  // ─── 수업 완료 ─────────────────────────────────────────────────────────────

  Future<void> completeLesson() async {
    final lessonId = state.lessonId;
    if (lessonId == null) return;
    debugPrint('[수업완료] completeLesson() 호출됨, lessonId=$lessonId, isRecording=${state.isRecording}');

    try {
      String? recordingUrl = state.recordingUrl;

      if (state.isRecording) {
        try {
          debugPrint('[수업완료] stopRecording 호출 시도');
          final resp = await _repo.stopRecording(lessonId);
          recordingUrl = resp.recordingUrl ?? recordingUrl;
        } catch (e) {
          debugPrint('[수업완료] stopRecording 실패: $e');
        }
        state = state.copyWith(isRecording: false, recordingUrl: recordingUrl);
      }

      debugPrint('[수업완료] completeLesson API 호출, recordingUrl=$recordingUrl');
      await _repo.completeLesson(lessonId, recordingUrl: recordingUrl);
      // 완료 후 잔액 갱신(확정차감은 24h 뒤지만, hold 반영분/상태를 최신화).
      _ref.invalidate(coinBalanceProvider);

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
  (ref) => LessonNotifier(LessonRepository(), ref),
);
