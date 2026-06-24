import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/lesson_model.dart';

class LessonRepository {
  final Dio _dio;
  StompClient? _stomp;
  String? _sessionId;

  LessonRepository({Dio? dio}) : _dio = dio ?? dioClient;

  // ─── HTTP ─────────────────────────────────────────────────────────────────

  Future<TokenResponse> fetchToken({
    required String channelName,
    required String uid,
    required String role,
  }) async {
    final response = await _dio.post('/lesson/token', data: {
      'channelName': channelName,
      'uid': uid,
      'role': role,
    });
    return TokenResponse.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<RecordingStartResponse> startRecording(int lessonId) async {
    final response = await _dio.post('/lesson/$lessonId/recording/start');
    return RecordingStartResponse.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<RecordingStopResponse> stopRecording(int lessonId) async {
    final response = await _dio.post('/lesson/$lessonId/recording/stop');
    return RecordingStopResponse.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<ImageUploadResponse> uploadImage(int lessonId, XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    final response = await _dio.post(
      '/lesson/$lessonId/images',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
    return ImageUploadResponse.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> completeLesson(int lessonId, {String? recordingUrl}) async {
    await _dio.post(
      '/lesson/$lessonId/complete',
      queryParameters:
          recordingUrl != null ? {'recordingUrl': recordingUrl} : null,
    );
  }

  // ─── STOMP ────────────────────────────────────────────────────────────────

  String get sessionId {
    _sessionId ??=
        DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return _sessionId!;
  }

  void connectStomp(
    String channelName,
    void Function(DrawEvent) onEvent,
  ) {
    _stomp = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        onConnect: (frame) {
          _stomp!.subscribe(
            destination: '/topic/lesson/$channelName/draw',
            callback: (frame) {
              if (frame.body == null) return;
              try {
                final json =
                    jsonDecode(frame.body!) as Map<String, dynamic>;
                final event = DrawEvent.fromJson(json);
                // echo 필터링: 내가 보낸 이벤트는 무시
                if (event.senderId == sessionId) return;
                onEvent(event);
              } catch (_) {}
            },
          );
        },
        reconnectDelay: const Duration(seconds: 3),
      ),
    );
    _stomp!.activate();
  }

  void sendDraw(String channelName, DrawEvent event) {
    if (_stomp == null || !_stomp!.connected) return;
    _stomp!.send(
      destination: '/app/lesson/$channelName/draw',
      body: jsonEncode(event.toJson()),
    );
  }

  void disconnectStomp() {
    _stomp?.deactivate();
    _stomp = null;
  }
}
